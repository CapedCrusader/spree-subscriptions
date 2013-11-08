module Spree::Admin::SubscriptionsHelper
  def linked_order_numbers(subscription)
    subscription.orders.map { |order|
      (link_to order.number, spree.admin_order_url(order)).html_safe
    }.join(',').html_safe
  end
end
