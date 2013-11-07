module Spree
  Variant.class_eval do
    # attr_accessible :num_subscription_units

    before_save :set_default_num_subscription_units

    delegate :subscribable?, :to => :product

    def set_default_num_subscription_units
      self.num_subscription_units = SpreeSubscriptions::Config.default_num_subscription_units if !self.num_subscription_units
    end
  end
end
