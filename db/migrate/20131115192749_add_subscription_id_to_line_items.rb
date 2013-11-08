class AddSubscriptionIdToLineItems < ActiveRecord::Migration
  def change
    add_column :spree_line_items, :subscription_id, :integer
  end
end
