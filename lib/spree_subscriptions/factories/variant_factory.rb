FactoryGirl.define do
  factory :subscribable_variant, :parent => :variant do
    # associations:
    product { |p| p.association(:subscribable_product) }
    num_subscription_units 4
  end
end
