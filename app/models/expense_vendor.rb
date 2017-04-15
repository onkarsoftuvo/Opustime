class ExpenseVendor < ActiveRecord::Base
  belongs_to :company

  has_many :expense_vendors_expenses , :dependent=> :destroy
  has_many :expenses , :through => :expense_vendors_expenses , :dependent=> :destroy

end
