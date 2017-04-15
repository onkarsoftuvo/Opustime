class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :no_doctors
      t.integer :monthly_price
      t.boolean :is_selected
      t.references :subscription, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
