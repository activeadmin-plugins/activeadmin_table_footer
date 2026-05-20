# frozen_string_literal: true

require "rails/engine"

module ActiveadminTableFooter
  class Engine < ::Rails::Engine
    config.to_prepare do
      require "activeadmin_table_footer/table_for_extension"
      require "activeadmin_table_footer/index_as_table_extension"

      ActiveAdmin::Views::TableFor.prepend(ActiveadminTableFooter::TableForExtension)
      ActiveAdmin::Views::IndexAsTable.prepend(ActiveadminTableFooter::IndexAsTableExtension)
    end
  end
end
