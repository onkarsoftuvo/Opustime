class CreateBusinessesExpenses < ActiveRecord::Migration
  def change
    create_table :businesses_expenses do |t|
      t.references :business, index: true, foreign_key: true
      t.references :expense, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
