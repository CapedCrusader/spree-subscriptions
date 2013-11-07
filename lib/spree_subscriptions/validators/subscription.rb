class SubscriptionValidator < ActiveModel::Validator 
  def validate(record) 
    unless Spree::Product.find_by_id(record.subscribable_product_id).subscribable?
      record.errors[:subscribable_product] << 'Should be a subscribable product'
    end
  end
end
