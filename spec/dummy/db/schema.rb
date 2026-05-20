# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table :customers, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :plans, force: true do |t|
    t.string  :name, null: false
    t.decimal :monthly_price, precision: 10, scale: 2, null: false, default: 0
    t.timestamps
  end

  create_table :subscriptions, force: true do |t|
    t.references :customer, foreign_key: true, null: false
    t.references :plan,     foreign_key: true, null: false
    t.integer :seats, null: false, default: 1
    t.boolean :is_operator, null: false, default: false
    t.timestamps
  end
end
