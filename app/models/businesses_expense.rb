class BusinessesExpense < ActiveRecord::Base
  belongs_to :business
  belongs_to :expense
end
