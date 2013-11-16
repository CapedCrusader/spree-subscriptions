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

    def subscription_renewal_error(subscription)
      @subscribed_by = subscription.email
      @subscription = subscription
      mail(:to => @subscribed_by, :subject => t(:subscription_renewal_error), :from => from_address)
    end
  end
end
