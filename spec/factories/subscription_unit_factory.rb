FactoryGirl.define do
  factory :subscription_unit, :class => Spree::SubscriptionUnit do
    # associations:
    subscribable_product { FactoryGirl.create(:product, :subscribable => true) }
    sequence(:name) {|n| "Subscription_Unit number #{n}" }
  end
end
