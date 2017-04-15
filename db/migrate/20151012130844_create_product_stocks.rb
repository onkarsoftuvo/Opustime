class CreateProductStocks < ActiveRecord::Migration
  def change
    create_table :product_stocks do |t|
      t.boolean :stock_level
      t.string :stock_type
      t.integer :quantity
      t.datetime :adjusted_at
      t.string :adjusted_by
      t.text :note
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
