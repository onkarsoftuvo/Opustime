class ProductStock < ActiveRecord::Base
  belongs_to :product
  belongs_to :invoice
  # validates :stock_level, inclusion: { in: [true, false] }
  validates :quantity , numericality: { only_integer: true }

  def stock_adjusted_by
  	User.find_by_id(self.adjusted_by).try(:full_name)
  end
  
end
