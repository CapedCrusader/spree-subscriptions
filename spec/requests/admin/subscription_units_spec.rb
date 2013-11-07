require 'spec_helper'

describe "SubscriptionUnit" do
  context "as_admin_user" do
    before do
      user = create(:admin_user, :email => "test@example.com")
      sign_in_as!(user)
    end

    before do
      visit spree.admin_path
    end

    context "accessing product subscription_units" do
      context "unsuscribable products" do
        it "should not have subscription_unit tab" do
          create(:base_product)
          click_link "Products"
          within('table.index tbody tr:nth-child(1)') { click_icon :edit }
          page.should_not have_content("Subscription Units")
        end
      end

      context "subscribable products" do
        before(:each) do
          @subscribable_product = create(:subscribable_product)
          click_link "Products"
          within('table.index tbody tr:nth-child(1)') { click_icon :edit }
        end

        it "should have subscription_unit tab" do
          page.should have_content("Subscription Units")
        end

        it "should let view product subscription_units" do
          subscription_unit = create(:subscription_unit, :subscribable_product => @subscribable_product)
          other_subscription_unit = create(:subscription_unit)
          click_link "Subscription Units"
          page.should have_content("Available subscription units")
          page.should have_content(subscription_unit.name)
          page.should_not have_content(other_subscription_unit.name)
        end
      end
    end

    context "managing an subscription_unit", js: true do
      before do
        @subscribable_product = create(:subscribable_product)
        click_link "Products"
        within('table.index tbody tr:nth-child(1)') { click_icon :edit }
      end

      context "creating an subscription_unit" do
        it "should let access the new subscription_unit page" do
          click_link "Subscription Units"
          click_link "New subscription unit"
        end

        it "should create a new subscription_unit without associated product" do
          click_link "Subscription Units"
          click_link "New subscription unit"
          fill_in "Name", :with => "Subscribable_Product subscription_unit number 4"
          click_button "Create"
          within("[data-hook='admin_product_subscription_unit_header']") { page.should have_content "Subscribable_Product subscription_unit number 4" }
        end

        it "should create a new subscription_unit with an associated product" do
          @product_subscription_unit = create(:base_product, :name => "Subscription_Unit number 4")
          click_link "Subscription Units"
          click_link "New subscription unit"
          select "Subscription_Unit number 4", :from => "Product"
          click_button "Create"
          click_link "Subscription Units"
          within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link 'Edit' }
          find_field('Product').find('option[selected]').text.should == "Subscription_Unit number 4"
        end

        it "should not let select subscribable product as associated product" do
          @product_subscription_unit = create(:base_product, :name => "Subscription_Unit number 4")
          click_link "Subscription Units"
          click_link "New subscription unit"

          page.should have_xpath("//*[@id='subscription_unit_subscribable_product_subscription_unit_id']/option", :count => 1)
        end
      end

      context "editing a product subscription_unit" do
        before do
          @subscription_unit = create(:subscription_unit, :subscribable_product => @subscribable_product)
          click_link "Subscription Units"
        end

        it "shoud let access the edit subscription_unit page" do
          within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link 'Edit' }
          find_field("subscription_unit_name").value.should == @subscription_unit.name
        end

        it "should let update an subscription_unit" do
          within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link 'Edit' }
          fill_in "Name", :with => "Subscribable_Product subscription_unit number 4"
          click_button "Update"
          page.should have_content "Subscription unit updated!"
          page.should have_content "Subscribable_Product subscription_unit number 4"
        end
      end

      context "showing a product subscription_unit" do
        before do
          @subscription_unit = create(:subscription_unit, :subscribable_product => @subscribable_product)
          @subscription = create(:ending_subscription, :subscribable_product => @subscribable_product)
        end

        it "should display the list of subscribers" do
          click_link "Subscription Units"
          within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link @subscription_unit.name }
          page.should have_content @subscription.email
        end

        it "should display only users subscribed to that subscription_unit" do
          @other_subscribable_product = create(:subscribable_product)
          @other_subscription = create(:ending_subscription, :subscribable_product => @other_subscribable_product, :email => "other@email.com")
          click_link "Subscription Units"
          within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link @subscription_unit.name }
          page.should_not have_content @other_subscription.email
        end

        it "should display only users that have remaining subscription_units" do
          @other_subscription = create(:ended_subscription, :subscribable_product => @subscribable_product, :email => "other@email.com")
          click_link "Subscription Units"
          within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link @subscription_unit.name }
          page.should_not have_content @other_subscription.email
        end

        context "shipping an subscription_unit" do
          before do
            SpreeSubscriptions::Config.use_delayed_job = false
            (0..5).each { |i| create(:ending_subscription, :subscribable_product => @subscribable_product) }
          end

          it "should show listing as 'subscribed'" do
            click_link "Subscription Units"
            within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link @subscription_unit.name }
            page.should have_content "Subscribed"
          end

          it "should be markable as shipped", js: false do
            click_link "Subscription Units"
            within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link @subscription_unit.name }
            click_link "Ship"
            #page.driver.browser.switch_to.alert.accept
            #page.find('.flash.notice'>Subscription unit successfully shipped</div>
            page.should have_content "successfully shipped"
          end

          context "after subscription_unit is shipped" do
            before do
              @subscription_unit.ship!
              (0..5).each { |i| create(:ending_subscription, :subscribable_product => @subscribable_product) }
              click_link "Subscription Units"
              within('table.index#listing_subscription_units tbody tr:nth-child(1)') { click_link @subscription_unit.name }
            end

            it "should not see the ship button" do
              page.should_not have_content "ship"
            end

            it "should show listing as 'shipped to'" do
              page.should have_content "Shipped to"
            end

            it "should display the list of user that received the subscription_unit" do
              page.should have_selector("table#subscriptions_listing tbody tr", :count =>  @subscription_unit.shipped_subscription_units.count)
            end
          end
        end
      end
    end
  end
end
