class ExpenseVendorsExpense < ActiveRecord::Base
  belongs_to :expense_vendor
  belongs_to :expense
end
