FactoryGirl.define do
  factory :shipped_subscription_unit, :class => Spree::ShippedSubscriptionUnit do
    # associations:
    subscription
  end
end
