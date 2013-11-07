class Spree::ShippedSubscriptionUnit < ActiveRecord::Base
  belongs_to :subscription_unit, :autosave => true
  belongs_to :subscription, :autosave => true

  # attr_accessible :subscription, :subscription_unit
end
