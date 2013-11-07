module Spree
  Order.class_eval do
    def create_subscriptions
      line_items.each do |line_item|
        if line_item.variant.subscribable?
          Subscription.subscribe!(
            :email => self.email, 
            :ship_address => self.ship_address,
            :subscribable_product => line_item.variant.product,
            :remaining_subscription_units => line_item.variant.num_subscription_units
          )
        end
      end
    end
  end
end
