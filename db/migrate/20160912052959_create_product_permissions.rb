class CreateProductPermissions < ActiveRecord::Migration
  def change
    create_table :product_permissions do |t|
      t.text :product_view
      t.text :product_create
      t.text :product_edit	
      t.text :product_stock
      t.text :product_delete
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
