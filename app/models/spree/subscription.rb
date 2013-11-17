class Spree::Subscription < ActiveRecord::Base
  belongs_to :subscribable_product, :class_name => 'Spree::Product'
  belongs_to :ship_address, :class_name => 'Spree::Address'
  has_many :line_items
  has_many :orders, through: :line_items
  has_many :shipped_subscription_units

  alias_method :shipping_address, :ship_address
  alias_method :shipping_address=, :ship_address=
  accepts_nested_attributes_for :ship_address
  
  validates_with SubscriptionValidator

  scope :eligible_for_shipping, where("remaining_subscription_units >= 1")
  
  state_machine :state, :initial => :active do
    event :cancel do
      transition :to => :canceled, :if => :allow_cancel?
    end

    after_transition :to => :canceled, :do => :handle_cancel
  end

  def self.subscribe!(opts)
    opts.to_options!.assert_valid_keys(:email, :ship_address, :subscribable_product, :remaining_subscription_units, :auto_renew)
    existing_subscription = self.where(:email => opts[:email], :subscribable_product_id => opts[:subscribable_product].id).first

    if existing_subscription
      self.renew_subscription(existing_subscription, opts[:remaining_subscription_units], opts[:ship_address])
    else
      subscription = self.new_subscription(opts[:email], opts[:subscribable_product], opts[:remaining_subscription_units], opts[:ship_address], opts[:auto_renew])
    end
  end

  def ended?
    remaining_subscription_units == 0
  end

  def ending?
    remaining_subscription_units == 1
  end

  def notify_ended!
    if SpreeSubscriptions::Config.use_delayed_job
      Spree::SubscriptionMailer.delay.subscription_ended_email(self)
    else
      Spree::SubscriptionMailer.subscription_ended_email(self).deliver
    end
  end

  def notify_ending!
    if SpreeSubscriptions::Config.use_delayed_job
      Spree::SubscriptionMailer.delay.subscription_ending_email(self)
    else
      Spree::SubscriptionMailer.subscription_ending_email(self).deliver
    end
  end

  def notify_renewal_error!(e=nil)
    error_text = nil

    if e
      bt = e.backtrace.join("\n")
      error_text =  "Unable to renew subscription for: id=#{self.id} - exception: #{e.message} - \n#{bt}"
    end

    if SpreeSubscriptions::Config.use_delayed_job
      Spree::SubscriptionMailer.delay.subscription_renewal_error_email(self,error_text)
    else
      Spree::SubscriptionMailer.subscription_renewal_error_email(self,error_text).deliver
    end
  end

  def ship!(subscription_unit)
    if !ended? && !shipped?(subscription_unit)
      transaction do
        shipped_subscription_units.create(:subscription_unit => subscription_unit)
        update_attribute(:remaining_subscription_units, remaining_subscription_units-1)

        if self.auto_renew && ended? && !self.canceled?
          begin
            Spree::SubscriptionRenewer.renew(self)
          rescue => e
            bt = e.backtrace.join("\n")
            Rails.logger.error "Unable to renew subscription for: id=#{self.id} - exception: #{e.message} - \n#{bt}"
            notify_renewal_error!(e)
          end
        else
          notify_ending! if ending?
          notify_ended! if ended?
        end
      end
    end
  end

  def shipped?(subscription_unit)
    !shipped_subscription_units.where(:id => subscription_unit.id).empty?
  end

  def allow_cancel?
    self.auto_renew && self.state != 'canceled'
  end

  private

  def handle_cancel
    # TODO: need to stop the next auto-purchase of another subscription
  end

  def self.new_subscription(email, subscribable_product, remaining_subscription_units, ship_address, auto_renew)
    self.create do |s|
      s.email            = email
      s.subscribable_product_id      = subscribable_product.id
      s.remaining_subscription_units = remaining_subscription_units
      s.ship_address     = ship_address
      s.auto_renew = auto_renew
    end
  end

  def self.renew_subscription(old_subscription, new_remaining_subscription_units, new_ship_address)
    total_remaining_subscription_units = old_subscription.remaining_subscription_units + new_remaining_subscription_units.to_i
    old_subscription.update_attribute(:remaining_subscription_units, total_remaining_subscription_units)
    old_subscription.update_attribute(:ship_address_id, new_ship_address.id)
    old_subscription
  end
end
