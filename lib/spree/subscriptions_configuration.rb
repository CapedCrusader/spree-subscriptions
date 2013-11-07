class Spree::SubscriptionsConfiguration < Spree::Preferences::Configuration
  preference :use_delayed_job, :boolean, :default => true
  preference :default_num_subscription_units, :integer, :default => 12
end
