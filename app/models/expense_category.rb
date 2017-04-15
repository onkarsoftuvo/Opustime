class ExpenseCategory < ActiveRecord::Base
  belongs_to :company

  has_many :expense_categories_expenses , :dependent=> :destroy
  has_many :expenses , :through => :expense_categories_expenses , :dependent=> :destroy 
  
end
