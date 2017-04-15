class ExpensePermission < ActiveRecord::Base
  include PermissionFormat

  belongs_to :owner

  serialize :expense_view , JSON
  serialize :expense_create , JSON
  serialize :expense_edit , JSON
  serialize :expense_delete , JSON
  scope :specific_attr , ->{ select('expense_view , expense_create , expense_edit , expense_delete')}
end
