class CreateShippedSubscriptionUnits < ActiveRecord::Migration
  def change
    create_table :spree_shipped_subscription_units do |t|
      t.references :subscription_unit
      t.references :subscription

      t.timestamps
    end
    add_index :spree_shipped_subscription_units, :subscription_unit_id
    add_index :spree_shipped_subscription_units, :subscription_id
  end
end
