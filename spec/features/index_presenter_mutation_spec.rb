# frozen_string_literal: true

require "rails_helper"

# Regression guard for a shared-state bug in IndexAsTableExtension.
#
# ActiveAdmin builds one PagePresenter per `index do ... end` when it loads the
# resource, and `get_page_presenter` hands that same object to every render
# (`ActiveAdmin::Views::Pages::Index#main_content`). Writing the footer wrapper
# back into that presenter therefore wrapped the previous wrapper on each
# render: retained closures and block call depth grew by one per request, until
# rendering an index raised SystemStackError in a long-lived process (~6k
# renders). Keep the presenter untouched — render against a copy.
RSpec.describe "Index page presenter across repeated renders", type: :feature do
  let!(:plan)         { Plan.create!(name: "Basic", monthly_price: 10) }
  let!(:customer)     { Customer.create!(name: "Acme") }
  let!(:subscription) { Subscription.create!(customer: customer, plan: plan, seats: 4) }

  def index_page_presenter
    ActiveAdmin.application.load!
    ActiveAdmin.application.namespaces[:admin]
               .resources
               .find { |resource| resource.resource_name.to_s == "Subscription" }
               .get_page_presenter(:index)
  end

  it "leaves PagePresenter#block the very same object after repeated renders" do
    presenter = index_page_presenter
    original_block = presenter.block

    5.times { visit "/admin/subscriptions" }

    expect(presenter.block).to equal(original_block)
  end

  it "still renders the footer on every render" do
    3.times do
      visit "/admin/subscriptions"

      within_table_for("subscriptions") do
        within_table_footer do
          expect(page).to have_table_cell(column: "Seats", exact_text: "4")
        end
      end
    end
  end
end
