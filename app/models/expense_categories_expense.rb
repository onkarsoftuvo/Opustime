class ExpenseCategoriesExpense < ActiveRecord::Base
  belongs_to :expense
  belongs_to :expense_category

  
end
