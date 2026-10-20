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

  # `table_for items, footer_data: show_totals && ->(c) { ... }` passes `false`
  # when the flag is off. A falsy callback means "no footer", same as the index
  # wrapper already assumes (`footer_proc && page_presenter.block`).
  describe "#footer_data with a falsy callback" do
    let(:table) { ActiveAdmin::Views::TableFor.allocate }

    it "treats false as no callback instead of raising" do
      table.instance_variable_set(:@footer_data_proc, false)

      expect(table.footer_data).to be_nil
    end

    it "treats nil as no callback" do
      table.instance_variable_set(:@footer_data_proc, nil)

      expect(table.footer_data).to be_nil
    end
  end
end
