class AddColumnProdIdToExpenseProduct < ActiveRecord::Migration
  def change
    add_column :expense_products, :prod_id, :string
  end
end
