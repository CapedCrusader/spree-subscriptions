require 'spec_helper'

describe Spree::ShippedSubscriptionUnit do

  it "should have a subscription" do
    shipped_subscription_unit = build(:shipped_subscription_unit)
    shipped_subscription_unit.should respond_to(:subscription)
  end

  it "should have an subscription_unit" do
    shipped_subscription_unit = build(:shipped_subscription_unit)
    shipped_subscription_unit.should respond_to(:subscription_unit)
  end

end
