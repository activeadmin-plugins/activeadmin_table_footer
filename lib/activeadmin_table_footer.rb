# frozen_string_literal: true

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
