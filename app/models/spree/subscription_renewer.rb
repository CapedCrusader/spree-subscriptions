module Spree
  class SubscriptionRenewer
    def self.create_new_order_from_subscription(subscription)
      # loosely from spree/core/lib/spree/core/controller_helpers/order.rb

      existing_order = subscription.orders.last

      currency = existing_order.currency

      new_order = Spree::Order.new(currency: currency)
      new_order.user = existing_order.user
      # See issue #3346 for reasons why this line is here
      new_order.created_by = existing_order.user
      new_order.save!
      new_order
    end

    def self.params_for_populator(line_item)
      params = Hash.new
      params[:variants] = Hash.new
      params[:variants][line_item.variant.id] = line_item.quantity

      params
    end

    def self.clone_subscription_line_item(new_line_item, existing_line_item)
      new_order= new_line_item.order

      if new_line_item.price != existing_line_item.price # has the price changed since they purchased?  If so, stick w/ the old price
        new_line_item.price = existing_line_item.price
        new_line_item.save!
        new_order.reload
      end

      new_order.ensure_updated_shipments # from the orders controller

      # These are in the orders controller.  TODO: need to revisit applying existing promotions to this order
      #fire_event('spree.cart.add')
      #fire_event('spree.order.contents_changed')
    end

    def self.renew(subscription)
      # create new order basaed on existing order
      new_order = create_new_order_from_subscription(subscription)
      populator = Spree::OrderPopulator.new(new_order, new_order.currency)
      
      existing_line_item =subscription.line_items.last
      if populator.populate(params_for_populator(existing_line_item))
        clone_subscription_line_item(new_order.line_items.first, existing_line_item)
        move_order_through_checkout(new_order, existing_line_item.order)
      else
        raise "Unable to populate new subscription order based on existing subscription: id=#{subscription.id}"
      end
    end

    def self.move_order_through_checkout(new_order, existing_order)
      while new_order.next; end

      new_order.ship_address_id = existing_order.ship_address_id
      new_order.bill_address_id = existing_order.bill_address_id

      new_order.save!

      # we need to make sure there are placeholder shipping rates in the target order
      new_order.shipments.reload # if we don't do this, shipments have a stale link to their orders and can_get_rates? fails
      new_order.refresh_shipment_rates

      # find any shipping rate used by the previous order
      selected_shipping_method_id = existing_order.shipments.last.selected_shipping_rate.shipping_method.id

      # copy the old selected shipping rates
      new_order.shipments.each do |shipment|
        new_selected_rate = shipment.shipping_rates.detect {|rate| rate.shipping_method_id == selected_shipping_method_id}
        if new_selected_rate
          shipment.selected_shipping_rate_id= new_selected_rate.id 
        else
          shipment.selected_shipping_rate_id= shipment.shipping_rates.first.id

          Rails.logger.warn "Unable to match selected shipping rates during subscription renewal"
          #TODO: discuss what best course of action here is
          # the safest is to probably barf so we don't overcharge on a higher rate
        end
      end

      while new_order.next; end

      # time to pay
      # copy the payment info
      existing_payment = existing_order.payments.detect {|p| p.completed?}
      new_payment = new_order.payments.build

      new_payment.payment_method_id = existing_payment.payment_method_id
      new_payment.source_type = existing_payment.source_type
      new_payment.source_id = existing_payment.source_id
      
      new_payment.save!

      # complete
      while new_order.next; end
    end
  end
end
