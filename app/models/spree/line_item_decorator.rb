module Spree
  LineItem.class_eval do
    belongs_to :subscription
    validates_numericality_of :quantity, :less_than_or_equal_to => 1, :if => :subscribable_product? 

    def subscribable_product?
      variant.product.subscribable?
    end
  end
end
