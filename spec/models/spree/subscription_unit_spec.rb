require 'spec_helper'

describe Spree::SubscriptionUnit do
  it "should be part of a subscribable_product" do
    subscription_unit = build(:subscription_unit)
    subscription_unit.should respond_to(:subscribable_product)
  end

  it "should have many shipped subscription_units" do
    subscription_unit = build(:subscription_unit)
    subscription_unit.should respond_to(:shipped_subscription_units)
  end

  it "should be related to a product which is the subscribable_product" do
    subscription_unit = create(:subscription_unit)
    subscription_unit.subscribable_product.should be_an_instance_of Spree::Product
  end

  it "should not be valid if no subscribable_product subscription_unit and no name is specified" do
    subscription_unit = build(:subscription_unit, :name => "", :subscribable_product_subscription_unit => nil)
    subscription_unit.should_not be_valid
  end

  it "should have a name like the name of the subscribable_product subscription_unit" do
    subscription_unit = create(:subscription_unit, :subscribable_product_subscription_unit => create(:base_product))
    subscription_unit.name.should equal(subscription_unit.subscribable_product_subscription_unit.name)
  end

  it "should have the name attribute if no subscribable_product subscription_unit is present" do
    subscription_unit = create(:subscription_unit, :name => "New Subscription_Unit")
    subscription_unit.name.should == "New Subscription_Unit"
  end

  it "should create a shipped subscription_unit when shipping subscription_unit" do
    subscription = create(:paid_subscription)
    subscription_unit = create(:subscription_unit, :subscribable_product => subscription.subscribable_product)
    expect{ subscription_unit.ship! }.to change(subscription_unit.shipped_subscription_units, :count).by(1)
  end

  it "should have shipped_at field to nil when not shipped" do
    subscription = create(:paid_subscription)
    subscription_unit = create(:subscription_unit, :subscribable_product => subscription.subscribable_product)
    subscription_unit.shipped_at.should be_nil
  end

  it "should have shipped_at field not nil when shipped" do
    subscription = create(:paid_subscription)
    subscription_unit = create(:subscription_unit, :subscribable_product => subscription.subscribable_product)
    expect{ subscription_unit.ship! }.to change{subscription_unit.shipped_at}
  end
end
