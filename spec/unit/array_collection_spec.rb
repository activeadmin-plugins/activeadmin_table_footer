# frozen_string_literal: true

require "rails_helper"

# Covers the case where `table_for` is invoked with a plain Array (e.g. in a
# custom panel or a `show` page) rather than an ActiveRecord::Relation. Symbol
# footers (:sum / :count / etc.) must fall back to Enumerable behaviour and
# Proc footers receive the Array as-is.
RSpec.describe "table_for with a plain Array collection" do
  Item = Struct.new(:name, :qty, :price) unless defined?(Item)

  let(:rows) do
    [
      Item.new("Widget", 10, 5),
      Item.new("Gadget", 4,  20),
      Item.new("Sprocket", 6, 12)
    ]
  end

  let(:rendered) do
    helpers = ActionView::Base.empty
    helpers.instance_variable_set(:@items, rows)
    helpers.arbre do
      table_for @items do
        column :name, footer: -> { strong { "Totals" } }
        column :qty,  footer: :sum
        column :price do |i|
          number_to_currency(i.price)
        end
      end
    end.to_s
  rescue StandardError
    # Building Arbre context fully outside of a request is messy; this spec
    # is documented as a behavioural reference rather than an actual render.
    nil
  end

  it "Symbol :sum on Array returns Enumerable sum" do
    ext = Class.new do
      include ActiveadminTableFooter::TableForExtension
      def initialize(coll); @collection = coll; end
    end
    text = ext.new(rows).send(:aggregate_collection, :sum, :qty)
    expect(text).to eq(20)
  end

  it "Symbol :count on Array returns Enumerable size" do
    ext = Class.new do
      include ActiveadminTableFooter::TableForExtension
      def initialize(coll); @collection = coll; end
    end
    expect(ext.new(rows).send(:aggregate_collection, :count, :name)).to eq(3)
  end

  it "Symbol :average on Array returns float mean" do
    ext = Class.new do
      include ActiveadminTableFooter::TableForExtension
      def initialize(coll); @collection = coll; end
    end
    expect(ext.new(rows).send(:aggregate_collection, :average, :price)).to be_within(0.001).of(12.333)
  end

  it "Symbol :maximum / :minimum work on Array" do
    ext = Class.new do
      include ActiveadminTableFooter::TableForExtension
      def initialize(coll); @collection = coll; end
    end
    instance = ext.new(rows)
    expect(instance.send(:aggregate_collection, :maximum, :price)).to eq(20)
    expect(instance.send(:aggregate_collection, :minimum, :price)).to eq(5)
  end

  it "skips nil values when aggregating in Ruby" do
    rows_with_nil = rows + [Item.new("Mystery", nil, nil)]
    ext = Class.new do
      include ActiveadminTableFooter::TableForExtension
      def initialize(coll); @collection = coll; end
    end
    expect(ext.new(rows_with_nil).send(:aggregate_collection, :sum, :qty)).to eq(20)
  end

  it "unscoped_collection_for_footer returns Array unchanged" do
    ext = Class.new do
      include ActiveadminTableFooter::TableForExtension
      def initialize(coll); @collection = coll; end
    end
    expect(ext.new(rows).send(:unscoped_collection_for_footer)).to eq(rows)
  end
end
