### 'Subscribable_Product' ###

module Spree
  Product.class_eval do
    #  attr_accessible :subscribable, :num_subscription_units, :subscription_units_attributes

    has_many :subscription_units, :dependent => :destroy, :foreign_key => "subscribable_product_id"
    has_many :subscriptions, :foreign_key => "subscribable_product_id"

    accepts_nested_attributes_for :subscription_units

    delegate_belongs_to :master, :num_subscription_units
    delegate_belongs_to :master, :auto_renew

    scope :subscribable, where(:subscribable => true)
    scope :unsubscribable, where(:subscribable => false)
    
  end
end
