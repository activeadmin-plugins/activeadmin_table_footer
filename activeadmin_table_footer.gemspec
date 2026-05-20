# frozen_string_literal: true

require_relative "lib/activeadmin_table_footer/version"

Gem::Specification.new do |spec|
  spec.name        = "activeadmin_table_footer"
  spec.version     = ActiveadminTableFooter::VERSION
  spec.authors     = ["Igor Fedoronchuk"]
  spec.email       = ["fedoronchuk@gmail.com"]

  spec.summary     = "Table footer DSL for ActiveAdmin index tables"
  spec.description = "Adds a `footer:` option to columns and a top-level `footer_data:` proc " \
                     "so index tables can render a <tfoot> with aggregated values in a single SQL query."
  spec.homepage    = "https://github.com/activeadmin-plugins/activeadmin_table_footer"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/releases"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activeadmin", ">= 3.5", "< 5.0"
  spec.add_dependency "arbre", ">= 1.4", "< 3.0"
  spec.add_dependency "railties", ">= 7.0"
end
