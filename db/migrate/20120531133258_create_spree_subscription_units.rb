class CreateSpreeSubscriptionUnits < ActiveRecord::Migration
  def change
    create_table :spree_subscription_units do |t|
      t.references :subscribable_product
      t.references :subscribable_product_subscription_unit
      t.string :name
      t.date :published_at

      t.timestamps
    end
    add_index :spree_subscription_units, :subscribable_product_id
    add_index :spree_subscription_units, :subscribable_product_subscription_unit_id, name: 'subscribable_product_suid'
  end
end
