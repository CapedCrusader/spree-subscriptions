module Spree
  Order.class_eval do
    has_many :subscriptions, through: :line_items
    def create_subscriptions
      line_items.each do |line_item|
        if line_item.variant.subscribable?
          subscription = Subscription.subscribe!(
            :email => self.email, 
            :ship_address => self.ship_address,
            :subscribable_product => line_item.variant.product,
            :remaining_subscription_units => line_item.variant.num_subscription_units,
            :auto_renew => line_item.variant.auto_renew                                                 
          )
          line_item.update_column(:subscription_id, subscription.id)
        end
      end
    end
  end
end
