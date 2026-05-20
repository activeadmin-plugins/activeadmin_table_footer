# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Subscriptions screenshot", type: :feature, js: true do
  before { Capybara.current_driver = :headless_chrome }
  after  { Capybara.use_default_driver }

  let!(:basic) { Plan.create!(name: "Basic", monthly_price: 10) }
  let!(:pro)   { Plan.create!(name: "Pro",   monthly_price: 25) }
  let!(:ent)   { Plan.create!(name: "Enterprise", monthly_price: 100) }
  let!(:c1)    { Customer.create!(name: "Acme") }
  let!(:c2)    { Customer.create!(name: "Globex") }
  let!(:c3)    { Customer.create!(name: "Initech") }

  before do
    Subscription.create!(customer: c1, plan: basic, seats: 10)
    Subscription.create!(customer: c2, plan: pro,   seats: 7,  is_operator: true)
    Subscription.create!(customer: c3, plan: ent,   seats: 25)
  end

  it "captures the subscriptions index with footer aggregates" do
    visit "/admin/subscriptions"
    expect(page).to have_css("#index_table_subscriptions tfoot")
    take_screenshot("subscriptions_with_footer_#{aa_major_version}")
  end

  def aa_major_version
    Gem::Version.new(ActiveAdmin::VERSION).segments.first(2).join("_")
  end
end
