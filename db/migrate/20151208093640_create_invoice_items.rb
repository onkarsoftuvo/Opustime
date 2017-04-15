class CreateInvoiceItems < ActiveRecord::Migration
  def change
    create_table :invoice_items do |t|
      t.string :source_item , lilmit:20
      t.string :item_type , lilmit:20
      t.float :unit_price
      t.integer :quantity
      t.string :tax
      t.float :discount
      t.float :total_price
      t.references :invoice, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
