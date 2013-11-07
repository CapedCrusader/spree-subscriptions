class Spree::SubscriptionUnit < ActiveRecord::Base
  belongs_to :subscribable_product, :class_name => "Spree::Product"
  belongs_to :subscribable_product_subscription_unit, :class_name => "Spree::Product"
  has_many :shipped_subscription_units

  # attr_accessible :name, :published_at, :shipped_at, :subscribable_product, :subscribable_product_subscription_unit_id

  delegate :subscriptions,:to => :subscribable_product

  validates :name, 
            :presence => true,
            :unless => "subscribable_product_subscription_unit.present?"

  def name
    subscribable_product_subscription_unit.present? ? subscribable_product_subscription_unit.name : read_attribute(:name)
  end

  def ship!
    subscriptions.eligible_for_shipping.each{ |s| s.ship!(self) }
    update_attribute(:shipped_at, Time.now)
  end

  def shipped?
    !shipped_at.nil?
  end
  
end
