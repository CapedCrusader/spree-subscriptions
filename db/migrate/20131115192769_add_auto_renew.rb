class AddAutoRenew < ActiveRecord::Migration
  def change
    add_column :spree_variants, :auto_renew, :boolean, default: false
    add_column :spree_subscriptions, :auto_renew, :boolean, default: false
  end
end
