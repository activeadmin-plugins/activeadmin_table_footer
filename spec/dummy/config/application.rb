# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "sprockets/railtie" if Gem.loaded_specs.key?("sprockets-rails")

Bundler.require(*Rails.groups)

require "activeadmin"
require "activeadmin_table_footer"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.active_record.legacy_connection_handling = false if Rails.gem_version < Gem::Version.new("7.1")
    config.hosts.clear if config.respond_to?(:hosts)
    config.action_controller.allow_forgery_protection = false
    config.secret_key_base = "test_secret_key_base_change_me_please_at_least_32_chars"
    config.cache_classes = true
    config.consider_all_requests_local = true
    config.action_mailer.delivery_method = :test
    config.action_dispatch.show_exceptions = :rescuable
    config.log_level = :warn
    config.active_support.deprecation = :stderr
  end
end
