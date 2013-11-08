require 'spec_helper'

describe "Subscription" do
  context "as_admin_user" do
    let(:subscription) { create(:subscription) }

    before do
      user = create(:admin_user, :email => "test@example.com")
      sign_in_as!(user)
      reset_spree_preferences do |config|
        config.default_country_id = create(:country).id
      end
      create(:state, :country_id => 1)
      visit spree.admin_path
    end

    context "viewing the list of subscriptions" do
      it "should show the orders associated with this subscription" do
        order1 = create(:order_with_subscription)
        ship_address = create(:address)
        order1.update_column(:ship_address_id, ship_address.id)
        order1.create_subscriptions
        order2 = create(:order_with_line_items)  # need to get a ship_address
        order2.update_column(:email, order1.email)
        order2.line_items << create(:line_item, :order => order2, :variant => order1.line_items.last.variant)
        order2.create_subscriptions
        
        click_link "Subscriptions"
        within('table#listing_subscriptions tbody tr:nth-child(1)') do
          page.should have_content("#{order1.number},#{order2.number}")
        end
      end  
    end

    context "editing a subscription" do
      before do
        create(:product, :name => 'sport subscribable_product', :available_on => '2011-01-06 18:21:13:', :subscribable => true)
        create(:product, :name => 'web subscribable_product', :available_on => '2011-01-06 18:21:13:', :subscribable => true)
        click_link "Subscriptions"
      end

      it "should be edited correctly" do
        within('table#listing_subscriptions tbody tr:nth-child(1)') { click_link("Edit") }
        select "web subscribable_product", :from => "Product"
        click_button "Update"
        page.should have_content("successfully updated!")
        find_field('Product').find('option[selected]').text.should == "web subscribable_product"
      end

      context "editing customer details" do
        before(:each) do
          # Go to customer details page
          within('table#listing_subscriptions tbody tr:nth-child(1)') { click_link("Edit") }
          within('.sidebar') { click_link("Customer Details") }
        end

        it "should be have customer details editable", :js => true do
          fill_in "Email", :with => "johnnyrocket@stardustcompany.com"
          within('#shipping') do
            fill_in 'First Name', :with => "Johnny"
            fill_in 'Last Name', :with => "Rocket"
            fill_in 'subscription_ship_address_attributes_address1', :with => "Stardust Street"
            fill_in 'City', :with => "Omega"
            fill_in 'Zip', :with => "66100"
            fill_in 'Phone', :with => "0871540143"
            select "United States of America", :from => "Country"

            all('#subscription_ship_address_attributes_state_id option')[1].select_option
          end
          click_button "Update"
          page.should have_content("The customer's details have been updated")
          page.should have_content("Product")
          within('.sidebar') { click_link("Customer Details") }
          find_field("subscription_email").value.should == "johnnyrocket@stardustcompany.com"
          within('#shipping') do
            find_field("subscription_ship_address_attributes_firstname").value.should == "Johnny"
            find_field("subscription_ship_address_attributes_lastname").value.should == "Rocket"
            find_field("subscription_ship_address_attributes_address1").value.should == "Stardust Street"
            find_field("subscription_ship_address_attributes_city").value.should == "Omega"
            find_field("subscription_ship_address_attributes_zipcode").value.should == "66100"
            find_field("subscription_ship_address_attributes_phone").value.should == "0871540143"
            find_field("subscription_ship_address_attributes_state_id").find('option[selected]').text.should == "Alabama"
            find_field("subscription_ship_address_attributes_country_id").find('option[selected]').text.should == "United States of America"
          end
        end
      end
    end
  end
end
