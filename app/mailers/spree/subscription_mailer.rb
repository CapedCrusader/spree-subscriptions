module Spree
  class SubscriptionMailer < BaseMailer
    def subscription_ending_email(subscription)
      @subscribed_by = subscription.email
      mail(:to => @subscribed_by, :subject => t(:subscription_ending), :from => from_address)
    end

    def subscription_ended_email(subscription)
      @subscribed_by = subscription.email
      mail(:to => @subscribed_by, :subject => t(:subscription_ended), :from => from_address)
    end

    def subscription_renewal_error_email(subscription, error_text=nil)
      @subscribed_by = subscription.email
      @subscription = subscription
      
      # either use the configured email or send it to every admin in the system
      
      cc = SpreeSubscriptions::Config[:renewal_error_email]
      unless cc
        dummy_user = Spree.user_class.new

        if dummy_user.respond_to?(:has_spree_role?) && dummy_user.respond_to?(:email)
          admin_users = Spree.user_class.all.select do |user|
            user.has_spree_role?('admin')
          end

          cc = admin_users.map(&:email)
        end
      end

      @error_text = error_text
      mail(:to => @subscribed_by, cc: cc, :subject => t(:subscription_renewal_error), :from => from_address)
    end
  end
end
