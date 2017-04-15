class CreateExpenseProducts < ActiveRecord::Migration
  def change
    create_table :expense_products do |t|
      t.string :name
      t.float :unit_cost_price
      t.integer :quantity
      t.references :expense, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
