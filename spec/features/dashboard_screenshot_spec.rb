# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard array table screenshot", type: :feature, js: true do
  before { Capybara.current_driver = :headless_chrome }
  after  { Capybara.use_default_driver }

  it "captures the in-memory Array table_for with footer" do
    visit "/admin/dashboard"
    expect(page).to have_css("tfoot td strong", text: "Totals")
    take_screenshot("dashboard_array_table_#{aa_major_version}")
  end

  def aa_major_version
    Gem::Version.new(ActiveAdmin::VERSION).segments.first(2).join("_")
  end
end
