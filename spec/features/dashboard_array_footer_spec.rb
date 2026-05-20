# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard panel — table_for with plain Array", type: :feature do
  before { visit "/admin/dashboard" }

  it "renders body rows for each POROin the array" do
    expect(page).to have_text("Widget")
    expect(page).to have_text("Gadget")
    expect(page).to have_text("Sprocket")
  end

  it "Symbol :sum aggregates in Ruby (Enumerable, not SQL)" do
    expect(page).to have_css("tfoot td strong", exact_text: "Totals")
    # qty: 10 + 4 + 6 = 20
    expect(page).to have_css('tfoot td[data-column="qty"]', exact_text: "20")
  end

  it "Proc footer receives the Array and runs view helpers" do
    # price: 5 + 20 + 12 = 37
    expect(page).to have_css('tfoot td[data-column="price"]', exact_text: "$37.00")
  end

  it "tfoot has one cell per header column (alignment preserved)" do
    header_cells = page.all("thead > tr > th").size
    footer_cells = page.all("tfoot > tr > td").size
    expect(footer_cells).to eq(header_cells)
  end

  it "does not issue any SQL while rendering the in-memory table" do
    queries = []
    callback = ->(_n, _s, _f, _i, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql]
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      visit "/admin/dashboard"
    end

    # No AR resource on the dashboard panel → no SQL whatsoever for our table.
    table_related = queries.select { |q| q.match?(/widgets?|gadgets?|sprockets?/i) }
    expect(table_related).to be_empty
  end
end
