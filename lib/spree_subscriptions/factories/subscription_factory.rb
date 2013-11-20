FactoryGirl.define do
  factory :subscription, :class => Spree::Subscription do
    # associations:
    subscribable_product { FactoryGirl.create(:subscribable_product) }
    ship_address { FactoryGirl.create(:address) }
    remaining_subscription_units 4
    email "johnny@rocket.com"
    
    after(:create) do |s|
      line_item = FactoryGirl.create(:line_item, order: FactoryGirl.create(:order_ready_to_ship), variant: s.subscribable_product.master)
      s.line_items << line_item
    end
  end

  factory :paid_subscription, :parent => :subscription do
    remaining_subscription_units 5
  end

  factory :ending_subscription, :parent => :subscription do
    remaining_subscription_units 2
  end

  factory :ended_subscription, :parent => :subscription do
    remaining_subscription_units 0
  end

  factory :customer_address, :class => Spree::Address do
    firstname 'Johnny'
    lastname 'Rocket'
    address1 'Sturdust Street'
    city 'Nebula'
    phone '01010101'
    zipcode 1111
    state_name 'Galaxy'
    country
  end
end
