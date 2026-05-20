# frozen_string_literal: true

module ActiveadminTableFooter
  # IndexAsTable#build constructs its own table_options hash and does not pass
  # unknown options through. We wrap the user block so the TableFor instance
  # receives @footer_data_proc before columns are evaluated.
  module IndexAsTableExtension
    def build(page_presenter, collection)
      footer_proc = page_presenter[:footer_data]

      if footer_proc && page_presenter.block
        original_block = page_presenter.block
        wrapped = lambda do |table|
          table.instance_variable_set(:@footer_data_proc, footer_proc)
          instance_exec(table, &original_block)
        end
        page_presenter.instance_variable_set(:@block, wrapped)
      end

      super
    end
  end
end
