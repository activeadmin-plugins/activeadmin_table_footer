# frozen_string_literal: true

ActiveAdmin.register Subscription do
  permit_params :customer_id, :plan_id, :seats, :is_operator

  filter :customer
  filter :plan
  filter :is_operator
  filter :seats

  index footer_data: ->(collection) {
          row = collection.joins(:plan).pick(
            Arel.sql("COALESCE(SUM(subscriptions.seats), 0)"),
            Arel.sql("COALESCE(SUM(subscriptions.seats * plans.monthly_price), 0)")
          )
          total_seats, total_cost = row || [0, 0]
          { total_seats: total_seats.to_i, total_cost: total_cost.to_f }
        } do
    selectable_column
    id_column
    column :customer
    column :plan
    column :is_operator, footer: -> { strong { "Total (all pages)" } }
    column "Seats", footer: -> { strong { footer_data[:total_seats].to_s } }, &:seats
    column :total_cost,
           footer: -> { strong { number_to_currency(footer_data[:total_cost]) } } do |row|
      number_to_currency row.total_cost
    end
    actions
  end
end
