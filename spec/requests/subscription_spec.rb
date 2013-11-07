require 'spec_helper'

describe "Subscription" do
  context "as_user", :js => true do
    before(:each) do

      country = create(:country)
      reset_spree_preferences do |config|
        config.default_country_id = country.id
      end
      create(:state, :country_id => country.id)

      create(:free_shipping_method)
      create(:payment_method)
      @product = create(:product, :name => 'sport subscribable_product', :available_on => '2011-01-06 18:21:13:', :subscribable => true, :num_subscription_units => 12)
      @user = create(:user, :email => "johnny@rocket.com", :password => "secret", :password_confirmation => "secret")
    end

    it "should be able to complete checkout with a subscribable_product in the order" do
      add_to_cart("sport subscribable_product")
      complete_checkout_with_login("johnny@rocket.com", "secret")
      complete_payment
      visit spree.account_path
      within("table.subscription-summary") do
        page.should have_content "sport subscribable_product"
        page.should have_content "12"
        page.should have_content "Active"
      end
    end

    it "should be able to complete checkout with a subscribable_product in the order" do
      add_to_cart("sport subscribable_product")
      complete_checkout_with_guest("johnny@rocket.com")
      complete_guest_payment
      sign_in_as!(@user)
      visit spree.account_path
      within("table.subscription-summary") do
        page.should have_content "sport subscribable_product"
        page.should have_content "12"
        page.should have_content "Active"
      end
    end

    context "after order completion" do
      before do
        add_to_cart("sport subscribable_product")
        complete_checkout_with_login("johnny@rocket.com", "secret")
      end

      it "should find a subscription area in account page" do
        visit spree.account_path
        page.should have_content "My subscriptions"
      end

      it "should not find an active subscription area in accont page if order is not paid" do
        visit spree.account_path
        page.should_not have_content "sport subscribable_product"
      end

      it "should find an active subscription after order is paid" do
        complete_payment
        visit spree.account_path
        within("table.subscription-summary") do
          page.should have_content "sport subscribable_product"
          page.should have_content "12"
          page.should have_content "Active"
          page.should have_content "Johnny Rocket"
        end
      end
    end

    context "on susequent orders" do
      it "should add subscription_unit numbers when renewing" do
        create_existing_subscription_for("johnny@rocket.com", @product, 2)
        add_to_cart("sport subscribable_product")
        complete_checkout_with_login("johnny@rocket.com", "secret")
        complete_payment
        visit spree.account_path
        within("table.subscription-summary") do
          page.should have_content "sport subscribable_product"
          page.should have_content "14" # 2 (remaining) + 12
          page.should have_content "Active"
        end
      end
    end

    context "checking out a subscribable product with variants" do
      before do
        @variant1, @variant2 = create_variants_for(@product)
      end

      it "should add variant subscription_unit number to subscription" do
        add_to_cart("sport subscribable_product", @variant2.options_text)
        complete_checkout_with_login("johnny@rocket.com", "secret")
        complete_payment
        visit spree.account_path
        within("table.subscription-summary") do
          page.should have_content "sport subscribable_product"
          page.should have_content "24"
          page.should have_content "Active"
        end
      end

      it "should add subscription_unit numbers when renewing with variants" do
        create_existing_subscription_for("johnny@rocket.com", @product, 6)
        add_to_cart("sport subscribable_product", @variant2.options_text)
        complete_checkout_with_login("johnny@rocket.com", "secret")
        complete_payment
        visit spree.account_path
        within("table.subscription-summary") do
          page.should have_content "sport subscribable_product"
          page.should have_content "30" # 6 (remaining) + 24
          page.should have_content "Active"
        end
      end
    end
  end
end
