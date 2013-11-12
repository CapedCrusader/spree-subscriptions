Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :subscriptions do
      resource :customer, :controller => "subscriptions/customer_details"
    end
    resources :products, :as => :subscribable_products do
      resources :subscription_units, :controller => "products/subscription_units"
      match "subscription_units/:id/ship", :to => "products/subscription_units#ship", :via => :get, :as => :ship_subscription_unit
    end
  end
end
