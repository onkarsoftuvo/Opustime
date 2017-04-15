class AddColumnStatusToExpenseProduct < ActiveRecord::Migration
  def change
    add_column :expense_products, :status, :boolean , :default=> true
  end
end
