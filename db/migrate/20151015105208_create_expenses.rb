class CreateExpenses < ActiveRecord::Migration
  def change
    create_table :expenses do |t|
      t.date :expense_date
      t.string :business_name
      t.string :vendor
      t.string :category
      t.float :total_expense
      t.string :tax
      t.float :tax_amount , :default=> 0.00
      t.text :note
      t.boolean :include_product_price , :default=> false 
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
