class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :item_code
      t.string :name
      t.string :serial_no
      t.string :supplier
      t.float :price
      t.float :price_inc_tax
      t.float :price_exc_tax
      t.string :tax
      t.float :cost_price
      t.integer :stock_number
      t.text :note
      t.boolean :status
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
