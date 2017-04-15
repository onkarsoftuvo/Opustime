class CreateExpenseVendorsExpenses < ActiveRecord::Migration
  def change
    create_table :expense_vendors_expenses do |t|
      t.references :expense_vendor, index: true, foreign_key: true
      t.references :expense, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
