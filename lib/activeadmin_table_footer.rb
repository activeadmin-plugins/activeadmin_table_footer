# frozen_string_literal: true

# Load ActiveAdmin first so `ActiveAdmin::Views::TableFor` and
# `IndexAsTable` exist by the time we prepend onto them. AA doesn't
# publish a load hook for itself (only `:active_admin_controller`), and
# `config.to_prepare` would fire too late for engines that require AA
# resources from an initializer. Sibling plugins (active_admin_sidebar,
# etc.) use the same pattern.
require "activeadmin"
require "activeadmin_table_footer/version"
require "activeadmin_table_footer/styles"

module ActiveadminTableFooter
  class << self
    attr_writer :footer_th_class, :footer_tr_class

    def footer_th_class
      @footer_th_class || Styles.footer_th_class
    end

    def footer_tr_class
      @footer_tr_class || Styles.footer_tr_class
    end

    def configure
      yield self
    end
  end
end

require "activeadmin_table_footer/engine" if defined?(Rails)
require "activeadmin_table_footer/table_for_extension"
require "activeadmin_table_footer/index_as_table_extension"

ActiveAdmin::Views::TableFor.prepend(ActiveadminTableFooter::TableForExtension)
ActiveAdmin::Views::IndexAsTable.prepend(ActiveadminTableFooter::IndexAsTableExtension)
