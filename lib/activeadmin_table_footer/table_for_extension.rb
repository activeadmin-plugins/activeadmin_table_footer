# frozen_string_literal: true

module ActiveadminTableFooter
  module TableForExtension
    def build(obj, *attrs)
      options = attrs.extract_options!
      @footer_data_proc = options.delete(:footer_data)
      super(obj, *attrs, options)
    end

    def footer_data
      return @footer_data if defined?(@footer_data)
      return (@footer_data = nil) unless @footer_data_proc
      @footer_data = @footer_data_proc.call(unscoped_collection_for_footer)
    end

    # The collection AA passes us is the paginated + ordered slice. Aggregates
    # over "all rows" need the underlying relation without LIMIT/OFFSET/ORDER —
    # otherwise SUM/COUNT on page 2 would only see the page-2 slice and ORDER
    # confuses some aggregate queries.
    def unscoped_collection_for_footer
      return @collection unless @collection.respond_to?(:except)
      @collection.except(:limit, :offset, :order)
    end

    def column(*args, &block)
      super
      col = @columns.last

      if @aatf_footer_row
        # Tfoot already exists — every subsequent column gets a cell
        # (with content if it has :footer, empty otherwise) so columns align.
        build_footer_cell_for(col)
      elsif column_has_footer?(col)
        # First column with :footer — open tfoot and back-fill empty cells
        # for all previously-added columns so the row aligns with headers.
        ensure_tfoot!
        @columns[0...-1].each { |prior| build_footer_cell_for(prior) }
        build_footer_cell_for(col)
      end
    end

    private

    def column_has_footer?(col)
      col.instance_variable_get(:@options).key?(:footer)
    end

    def build_footer_cell_for(col)
      within @aatf_footer_row do
        column_key = column_key_for(col)
        # Always include `col col-<key>` so capybara_active_admin matchers
        # (`have_table_cell(column: ...)`) work in both AA 3 and AA 4 — the
        # selector convention is `td.col.col-<key>`.
        compat_classes = column_key ? "col col-#{column_key}" : "col"
        classes = [col.html_class, compat_classes, ActiveadminTableFooter.footer_th_class]
                    .reject { |c| c.nil? || c.to_s.empty? }
                    .join(" ")
        attrs = { class: classes.empty? ? nil : classes }
        attrs[:"data-column"] = column_key if column_key
        td(**attrs) do
          render_footer_value(col) if column_has_footer?(col)
        end
      end
    end

    def column_key_for(col)
      # AA 4 exposes Column#title_id; AA 3 does not — derive from title.
      if col.respond_to?(:title_id) && col.title_id.respond_to?(:presence)
        return col.title_id.presence
      end
      title = col.title.to_s
      return nil if title.empty?
      title.parameterize(separator: "_")
    end

    def ensure_tfoot!
      return if @aatf_footer_row
      tfoot_classes = ActiveadminTableFooter.footer_tr_class
      tfoot do
        @aatf_footer_row = tr(class: tfoot_classes.presence)
      end
    end

    def render_footer_value(col)
      footer = col.instance_variable_get(:@options)[:footer]
      case footer
      when nil
        nil
      when Symbol
        text_node aggregate_collection(footer, col.data).to_s
      when Proc
        arg = unscoped_collection_for_footer
        result = footer.arity == 0 ? instance_exec(&footer) : instance_exec(arg, &footer)
        text_node(result.to_s) unless result.is_a?(Arbre::Element)
      else
        text_node footer.to_s
      end
    end

    # Symbol footer (`:sum`, `:count`, ...) works for both AR relations and
    # plain Arrays. AR uses native SQL aggregates; Arrays fall back to
    # in-Ruby Enumerable equivalents.
    def aggregate_collection(method, attribute)
      scope = unscoped_collection_for_footer
      if ar_relation?(scope)
        scope.public_send(method, attribute)
      else
        values = Array(scope).map { |r| r.public_send(attribute) }.compact
        case method
        when :sum     then values.sum
        when :count   then values.size
        when :average then values.empty? ? 0 : values.sum.to_f / values.size
        when :minimum then values.min
        when :maximum then values.max
        else scope.public_send(method, attribute)
        end
      end
    end

    def ar_relation?(scope)
      defined?(ActiveRecord::Relation) && scope.is_a?(ActiveRecord::Relation)
    end
  end
end
