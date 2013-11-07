class AddShippedToSpreeSubscriptionUnits < ActiveRecord::Migration
  def change
    add_column :spree_subscription_units, :shipped_at, :datetime
  end
end
