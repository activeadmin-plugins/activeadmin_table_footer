# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveadminTableFooter::TableForExtension do
  describe ActiveAdmin::Views::TableFor do
    it "prepends the extension" do
      expect(ActiveAdmin::Views::TableFor.ancestors).to include(described_class)
    end

    it "exposes #footer_data memoized" do
      expect(ActiveAdmin::Views::TableFor.instance_method(:footer_data)).to be_a(UnboundMethod)
    end
  end
end
