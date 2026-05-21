# frozen_string_literal: true

require "rails/engine"

module ActiveadminTableFooter
  # Empty engine — kept so Rails recognizes this gem as an engine on
  # boot. Patches are applied eagerly from
  # `lib/activeadmin_table_footer.rb` so they are in place before AA
  # resources are loaded (even when consuming engines `require` admin
  # files from an initializer).
  class Engine < ::Rails::Engine
  end
end
