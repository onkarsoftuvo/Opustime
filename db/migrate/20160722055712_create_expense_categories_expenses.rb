class CreateExpenseCategoriesExpenses < ActiveRecord::Migration
  def change
    create_table :expense_categories_expenses do |t|
      t.references :expense, index: true, foreign_key: true
      t.references :expense_category, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
