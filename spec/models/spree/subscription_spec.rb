require 'spec_helper'

describe Spree::Subscription do
  it "should have shipped subscription_units" do
    subscription = build(:subscription)
    subscription.should respond_to(:shipped_subscription_units)
  end

  context "when shipping subscriptions" do
    let(:subscription) { create(:paid_subscription) }
    let(:subscription_unit) { create(:subscription_unit, :subscribable_product => subscription.subscribable_product) }

    it "should ship subscription_units inside a transaction" do
      subscription.should_receive :transaction
      subscription.ship!(subscription_unit)
    end

    it "should not reship an subscription_unit already shipped" do
      subscription.ship!(subscription_unit)
      expect{ subscription.ship!(subscription_unit) }.not_to change(subscription.shipped_subscription_units, :count)
    end

    it "should have a method to know if it has been shipped" do
      subscription.shipped?(subscription_unit).should be_false
      subscription.ship!(subscription_unit)
      subscription.shipped?(subscription_unit).should be_true
    end

    it "should decrease remaining subscription_units if subscription sent" do
      expect{ subscription.ship!(subscription_unit) }.to change(subscription, :remaining_subscription_units).by(-1)
    end

    it "should not decrease remaining subscription_units if subscription not sent" do
      subscription.update_attribute(:remaining_subscription_units, 0)
      expect{ subscription.ship!(subscription_unit) }.not_to change(subscription, :remaining_subscription_units)
    end
  end

  context "when a subscription is ending" do
    let(:subscription) { create(:ending_subscription) }
    let(:subscription_unit) { create(:subscription_unit, :subscribable_product => subscription.subscribable_product) }

    context "without delayed_job" do
      before(:all) do
        SpreeSubscriptions::Config.use_delayed_job = false
      end

      before(:each) do
        ActionMailer::Base.deliveries = []
      end

      it "should send an email when the subscription is left with one subscription_unit" do
        expect{ subscription.ship!(subscription_unit) }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "should send an email when the subscription is left with zero subscription_units" do
        expect{ subscription.ship!(subscription_unit) }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "should not resend email when the subscription is already at zero subscription_units" do
        subscription.stub(:shipped?).and_return(true)
        expect{ subscription.ship!(subscription_unit) }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context "with delayed_job" do
      before(:all) do
        SpreeSubscriptions::Config.use_delayed_job = true
        Spree::SubscriptionMailer.stub(:delay).and_return(Spree::SubscriptionMailer)
      end

      it "should use delay when sending emails" do
        Spree::SubscriptionMailer.should_receive(:delay).twice
        subscription.notify_ended!
        subscription.notify_ending!
      end
    end
  end

  context "when adding a subscription" do
    it "should be valid if product is subscribable" do
      subscription = build(:subscription, :subscribable_product => create(:subscribable_product))
      subscription.should be_valid
    end

    it "should not be valid if product is not subscribable" do
      subscription = build(:subscription, :subscribable_product => create(:base_product))
      subscription.should_not be_valid
    end
  end

  context "when renewing a subscription" do
    let(:subscription) { create(:paid_subscription) }

    it "should update remaining subscription_units" do
      renewal = Spree::Subscription.subscribe!(
        :email => subscription.email,
        :ship_address => subscription.ship_address,
        :subscribable_product => subscription.subscribable_product,
        :remaining_subscription_units => 5
      )
      renewal.remaining_subscription_units.should == 10
    end

    it "should update ship address with latest ship address" do
      new_ship_address = create(:customer_address)
      renewal = Spree::Subscription.subscribe!(
        :email => subscription.email,
        :ship_address => new_ship_address,
        :subscribable_product => subscription.subscribable_product,
        :remaining_subscription_units => 5
      )
      subscription.ship_address.id.should_not == renewal.ship_address.id
    end
  end

  context "during an order" do
    let(:order) { create(:order_with_subscription) }

    context "when order is not completed yet" do
      it "should be associated to an order line item" do
        order.line_items.first.variant.product.subscribable.should be_true
      end

      it "should not be created before order completetion" do
        subscribable_product = order.line_items.first.variant.product
        subscription = Spree::Subscription.where(:subscribable_product_id => subscribable_product.id).first
        subscription.should be_nil
      end
    end

    context "when order is completed" do
      context "when user is not already subscribed" do
        before do
          # Field required to complete the order
          order.bill_address = create(:address)
          order.ship_address = create(:address)
          create(:inventory_unit, :order => order, :state => 'shipped')
          # Finalize order
          order.finalize!
        end

        let(:subscription) { Spree::Subscription.where(:subscribable_product_id => order.line_items.first.variant.product.id).first }

        it "should not be created on order completetion" do
          subscription.should be_nil
        end

        it "should have active status if order is paid" do
          order.payments << create(:payment, :order => order, :amount => order.total)
          # Capture payment
          order.payments.first.capture!
          subscribable_product = order.line_items.first.variant.product
          subscription = Spree::Subscription.where(:email => order.user.email, :subscribable_product_id => subscribable_product.id).first
          subscription.state.should == "active"
        end
      end

      context "when user is already subscribed" do
        before do
          # Create a subscription with same user and prooduct
          user = order.user
          product = order.line_items.first.variant.product
          Spree::Subscription.create(:email => user.email, :subscribable_product_id => product.id)
        end

        let(:subscription) { Spree::Subscription.where(:subscribable_product_id => order.line_items.first.variant.product.id).first }

        context "before order completion" do
          it "should already exists" do
            subscription.should_not be_nil
          end
        end

        context "after order completion" do
          before do
            # Field required to complete the order
            order.bill_address = create(:address)
            order.ship_address = create(:address)
            create(:inventory_unit, :order => order, :state => 'shipped')
            # Finalize order
            order.finalize!
          end

          let(:subscriptions) { Spree::Subscription.where(:subscribable_product_id => order.line_items.first.variant.product.id) }

          it "should not have to be created as new" do
            subscriptions.count.should == 1
          end
        end
      end
    end
  end
end
