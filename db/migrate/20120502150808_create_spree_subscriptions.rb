class CreateSpreeSubscriptions < ActiveRecord::Migration
  def change
    create_table :spree_subscriptions do |t|
      t.references :subscribable_product
      t.references :ship_address
      t.string :email
      t.string :state
      t.integer :remaining_subscription_units
      t.timestamps
    end
  end
end
