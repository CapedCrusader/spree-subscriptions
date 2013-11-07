require 'spec_helper'

describe Spree::Variant do
  let(:variant) { create(:subscribable_variant) }
  let(:variant_without_num_subscription_units) { create(:subscribable_variant, :num_subscription_units => "")}
  let(:base_product_variant) { create(:variant) }

  it "should respond to num_subscription_units" do
    variant.should respond_to :num_subscription_units
  end

  it "should use default value if not specified" do
    variant_without_num_subscription_units.num_subscription_units.should == SpreeSubscriptions::Config.default_num_subscription_units
  end

  it "should respond to subscribable? method" do
    variant.should respond_to :subscribable?
  end

  it "should respond to subscribable? with true" do
    variant.subscribable?.should be_true
  end

  it "should have subscribable to false by default" do
    base_product_variant.subscribable?.should be false
  end

end
