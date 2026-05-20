# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Subscriptions index footer", type: :feature do
  let!(:plan_basic) { Plan.create!(name: "Basic", monthly_price: 10) }
  let!(:plan_pro)   { Plan.create!(name: "Pro",   monthly_price: 25) }
  let!(:customer1)  { Customer.create!(name: "Acme") }
  let!(:customer2)  { Customer.create!(name: "Globex") }

  let!(:sub1) { Subscription.create!(customer: customer1, plan: plan_basic, seats: 10) }
  let!(:sub2) { Subscription.create!(customer: customer2, plan: plan_pro,   seats: 7) }

  before { visit "/admin/subscriptions" }

  it "renders body rows for each subscription" do
    expect(page).to have_table_row(count: 2)
    within "tr#subscription_#{sub1.id}" do
      expect(page).to have_text("Acme")
      expect(page).to have_text("10")
      expect(page).to have_text("$100.00")
    end
    within "tr#subscription_#{sub2.id}" do
      expect(page).to have_text("Globex")
      expect(page).to have_text("7")
      expect(page).to have_text("$175.00")
    end
  end

  it "renders a tfoot with aggregated totals across all rows" do
    expected_seats = sub1.seats + sub2.seats           # 17
    expected_cost  = sub1.total_cost + sub2.total_cost # 100 + 175 = 275

    within_table_for("subscriptions") do
      within_table_footer do
        expect(page).to have_table_cell(column: "Is Operator", exact_text: "Total (all pages)")
        expect(page).to have_table_cell(column: "Seats",       exact_text: expected_seats.to_s)
        expect(page).to have_table_cell(column: "Total Cost",  exact_text: ActionController::Base.helpers.number_to_currency(expected_cost))
      end
    end
  end

  describe "footer aggregates across ALL pages (not just visible)" do
    # Create more rows than AA's default per-page (30) to force pagination.
    # Spread seats so that the page-1 sum differs from the full total.
    let!(:extra_subscriptions) do
      40.times.map do |i|
        plan = (i.even? ? plan_basic : plan_pro)  # alternate plans
        Subscription.create!(customer: customer1, plan: plan, seats: i + 1)
      end
    end

    let(:all_rows_seats_total) do
      Subscription.sum(:seats)
    end

    let(:all_rows_cost_total) do
      Subscription.includes(:plan).sum { |s| s.seats * s.plan.monthly_price }
    end

    it "visible body shows only one page worth, but footer aggregates everything" do
      visit "/admin/subscriptions"

      # Pagination active: more than 1 page, default per_page = 30
      expect(page).to have_text("Next")
      visible_rows = page.all("tbody > tr").size
      expect(visible_rows).to be <= 30
      expect(Subscription.count).to be > visible_rows

      within_table_for("subscriptions") do
        within_table_footer do
          expect(page).to have_table_cell(column: "Seats",      exact_text: all_rows_seats_total.to_s)
          expect(page).to have_table_cell(column: "Total Cost", exact_text: ActionController::Base.helpers.number_to_currency(all_rows_cost_total))
        end
      end
    end

    it "footer values are identical on page 2 (same scope, different visible slice)" do
      visit "/admin/subscriptions?page=2"

      page2_rows = page.all("tbody > tr").map { |tr| tr["id"] }
      visit "/admin/subscriptions?page=1"
      page1_rows = page.all("tbody > tr").map { |tr| tr["id"] }
      expect(page1_rows & page2_rows).to be_empty   # disjoint

      [1, 2].each do |p|
        visit "/admin/subscriptions?page=#{p}"
        within_table_for("subscriptions") do
          within_table_footer do
            expect(page).to have_table_cell(column: "Seats",      exact_text: all_rows_seats_total.to_s)
            expect(page).to have_table_cell(column: "Total Cost", exact_text: ActionController::Base.helpers.number_to_currency(all_rows_cost_total))
          end
        end
      end
    end

    it "filter narrows footer even when narrowed scope still spans multiple pages" do
      # plan_basic gets every even-indexed seat: i = 0,2,4,...,38 → seats = 1,3,5,...,39
      # Plus original sub1 (seats: 10) on plan_basic.
      basic_subs = Subscription.where(plan: plan_basic)
      expected_seats = basic_subs.sum(:seats)
      expected_cost  = basic_subs.sum { |s| s.seats * s.plan.monthly_price }

      visit "/admin/subscriptions?q[plan_id_eq]=#{plan_basic.id}"

      within_table_for("subscriptions") do
        within_table_footer do
          expect(page).to have_table_cell(column: "Seats",      exact_text: expected_seats.to_s)
          expect(page).to have_table_cell(column: "Total Cost", exact_text: ActionController::Base.helpers.number_to_currency(expected_cost))
        end
      end
    end
  end

  describe "footer recalculates with each filter" do
    it "single-customer filter narrows totals to that customer" do
      visit "/admin/subscriptions?q[customer_id_eq]=#{customer1.id}"

      within_table_for("subscriptions") do
        within_table_footer do
          expect(page).to have_table_cell(column: "Seats",      exact_text: "10")
          expect(page).to have_table_cell(column: "Total Cost", exact_text: "$100.00")
        end
      end
    end

    it "plan filter narrows totals to subscriptions on that plan" do
      visit "/admin/subscriptions?q[plan_id_eq]=#{plan_pro.id}"

      within_table_for("subscriptions") do
        within_table_footer do
          expect(page).to have_table_cell(column: "Seats",      exact_text: "7")
          expect(page).to have_table_cell(column: "Total Cost", exact_text: "$175.00")
        end
      end
    end

    it "seats range filter recalculates totals from matching rows only" do
      Subscription.create!(customer: customer1, plan: plan_pro, seats: 50)
      visit "/admin/subscriptions?q[seats_gteq]=10"

      within_table_for("subscriptions") do
        within_table_footer do
          # rows with seats >= 10: sub1 (10 × $10 = 100) + new (50 × $25 = 1250) = 60 seats, $1,350
          expect(page).to have_table_cell(column: "Seats",      exact_text: "60")
          expect(page).to have_table_cell(column: "Total Cost", exact_text: "$1,350.00")
        end
      end
    end

    it "boolean is_operator filter narrows scope and footer together" do
      Subscription.create!(customer: customer1, plan: plan_pro, seats: 3, is_operator: true)
      visit "/admin/subscriptions?q[is_operator_eq]=true"

      within_table_for("subscriptions") do
        within_table_footer do
          expect(page).to have_table_cell(column: "Seats",      exact_text: "3")
          expect(page).to have_table_cell(column: "Total Cost", exact_text: "$75.00")
        end
      end
    end

    it "non-matching filter renders zero totals (empty scope)" do
      visit "/admin/subscriptions?q[seats_gteq]=999"

      next unless page.has_css?("#index_table_subscriptions tfoot")

      within_table_for("subscriptions") do
        within_table_footer do
          expect(page).to have_table_cell(column: "Seats",      exact_text: "0")
          expect(page).to have_table_cell(column: "Total Cost", exact_text: "$0.00")
        end
      end
    end
  end
end
