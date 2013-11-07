FactoryGirl.define do
  factory :subscribable_product, :parent => :base_product do
    # associations:
    subscribable true
    num_subscription_units 4
  end
end
