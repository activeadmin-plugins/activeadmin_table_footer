# frozen_string_literal: true

# A small Struct used to demonstrate that `table_for` + footer DSL work with
# a plain Array of POROs (no ActiveRecord involved).
DashboardItem = Struct.new(:name, :qty, :price, keyword_init: true) unless defined?(DashboardItem)

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    panel "Top items (in-memory Array — no SQL)" do
      items = [
        DashboardItem.new(name: "Widget",   qty: 10, price: 5),
        DashboardItem.new(name: "Gadget",   qty: 4,  price: 20),
        DashboardItem.new(name: "Sprocket", qty: 6,  price: 12)
      ]

      table_for items do
        column :name,  footer: -> { strong { "Totals" } }
        column :qty,   footer: :sum
        column :price, footer: ->(arr) { number_to_currency(arr.sum(&:price)) } do |i|
          number_to_currency(i.price)
        end
      end
    end
  end
end
