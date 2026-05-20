# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("dummy/config/environment", __dir__)

abort("Rails is in production!") if Rails.env.production?

require "rspec/rails"
require "capybara/rspec"
require "capybara/active_admin/rspec"
require_relative "support/tailwind_setup"

ActiveRecord::Migration.maintain_test_schema! if ActiveRecord::Migration.respond_to?(:maintain_test_schema!)

# Load schema into the in-memory sqlite database
load File.expand_path("dummy/db/schema.rb", __dir__)

Capybara.default_driver       = :rack_test
Capybara.javascript_driver    = :rack_test
Capybara.default_max_wait_time = 2

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include Rails.application.routes.url_helpers
end
