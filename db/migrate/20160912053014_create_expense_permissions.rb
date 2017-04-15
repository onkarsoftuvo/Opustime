class CreateExpensePermissions < ActiveRecord::Migration
  def change
    create_table :expense_permissions do |t|
      t.text :expense_view
      t.text :expense_create
      t.text :expense_edit
      t.text :expense_delete
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
