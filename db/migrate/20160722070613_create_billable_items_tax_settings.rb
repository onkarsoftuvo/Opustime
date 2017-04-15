class CreateBillableItemsTaxSettings < ActiveRecord::Migration
  def change
    create_table :billable_items_tax_settings do |t|
      t.references :billable_item, index: true, foreign_key: true
      t.references :tax_setting, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
