module Spree
  module Admin
    module Products
      class SubscriptionUnitsController < Spree::Admin::BaseController
        before_filter :load_subscribable_product
        before_filter :load_subscription_unit, :only => [:show, :edit, :update, :destroy, :ship]
        before_filter :load_products, :except => [:show, :index, :destroy]

        def show
          if @subscription_unit.shipped?
            @product_subscriptions = @subscription_unit.shipped_subscription_units.map { |shipped_subscription_unit| shipped_subscription_unit.subscription }.compact
          else
            @product_subscriptions = Subscription.eligible_for_shipping.where(:subscribable_product_id => @subscribable_product.id)
          end
          respond_to do |format|
            format.html
            format.pdf do
              addresses_list = @product_subscriptions.map { |s| s.ship_address }
              labels = SubscriptionUnitPdf.new(addresses_list, view_context)
              send_data labels.document.render, :filename => "#{@subscription_unit.name}.pdf", :type => "application/pdf", disposition: "inline"
            end
          end
        end

        def index
          @subscription_units = SubscriptionUnit.where(:subscribable_product_id => @subscribable_product.id)
        end

        def update
          if @subscription_unit.update_attributes(params[:subscription_unit].permit(:name, :published_at, :shipped_at, :subscribable_product, :subscribable_product_subscription_unit_id))
            flash[:notice] = t('subscription_unit_updated')
            redirect_to admin_subscribable_product_subscription_unit_path(@subscribable_product, @subscription_unit)
          else
            flash[:error] = t(:subscription_unit_not_updated)
            render :action => :edit
          end
        end

        def new
          @subscription_unit = @subscribable_product.subscription_units.build
        end

        def create          
          if (new_subscription_unit = @subscribable_product.subscription_units.create(params[:subscription_unit].permit(:name, :published_at, :shipped_at, :subscribable_product, :subscribable_product_subscription_unit_id)))
            flash[:notice] = t('subscription_unit_created')
            redirect_to admin_subscribable_product_subscription_unit_path(@subscribable_product, new_subscription_unit)
          else
            flash[:error] = t(:subscription_unit_not_created)
            render :new
          end
        end

        def destroy
          if !@subscription_unit.shipped? && @subscription_unit.destroy! 
            flash[:notice]  = t('subscription_unit_destroyed')
            redirect_to admin_subscribable_product_path(@subscribable_product)
          else
            flash[:error]  = t('subscription_unit_not_destroyed')
            redirect_to admin_subscribable_product_subscription_units_path(@subscribable_product, @subscription_unit)
          end
        end

        def ship
          if @subscription_unit.shipped?
            flash[:error]  = t('subscription_unit_not_shipped')
          else
            @subscription_unit.ship!
            flash[:notice]  = t('subscription_unit_shipped')
          end
          redirect_to admin_subscribable_product_subscription_units_path(@subscribable_product, @subscription_unit)
        end

        private

        def load_subscribable_product
          @subscribable_product = Product.find_by_permalink(params[:subscribable_product_id])
          @product = @subscribable_product # useful to display product_tab menu
        end

        def load_subscription_unit
          @subscription_unit = SubscriptionUnit.find(params[:id])
        end

        def load_products
          @products = Product.unsubscribable.map { |product| [product.name, product.id] }
        end
      end
    end
  end
end

