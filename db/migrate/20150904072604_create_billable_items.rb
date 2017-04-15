class CreateBillableItems < ActiveRecord::Migration
  def change
    create_table :billable_items do |t|
      t.string :item_code
      t.string :name
      t.integer :price
      t.boolean :include_tax
      t.integer :tax
      t.text :concession_price
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
