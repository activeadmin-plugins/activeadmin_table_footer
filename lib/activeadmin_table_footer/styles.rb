# frozen_string_literal: true

module ActiveadminTableFooter
  module Styles
    TAILWIND_TH = "px-3 py-2 bg-gray-50 dark:bg-gray-800/50 font-semibold border-t border-gray-200 dark:border-gray-700 text-left"

    module_function

    def aa_v4?
      Gem::Version.new(ActiveAdmin::VERSION) >= Gem::Version.new("4.0.0.beta1")
    end

    def footer_th_class
      aa_v4? ? TAILWIND_TH : ""
    end

    def footer_tr_class
      aa_v4? ? "" : "footer"
    end
  end
end
