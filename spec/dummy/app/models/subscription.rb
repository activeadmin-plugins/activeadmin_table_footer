# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :customer
  belongs_to :plan

  def total_cost
    seats * plan.monthly_price
  end

  def self.ransackable_attributes(_ = nil)
    %w[id customer_id plan_id seats is_operator created_at updated_at]
  end

  def self.ransackable_associations(_ = nil)
    %w[customer plan]
  end
end
