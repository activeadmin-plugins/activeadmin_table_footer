# frozen_string_literal: true

class Customer < ApplicationRecord
  has_many :subscriptions, dependent: :destroy

  def display_name
    name
  end

  def self.ransackable_attributes(_ = nil)
    %w[id name created_at updated_at]
  end

  def self.ransackable_associations(_ = nil)
    %w[subscriptions]
  end
end
