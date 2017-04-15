class CreateBillableItemsConcessions < ActiveRecord::Migration
  def change
    create_table :billable_items_concessions do |t|
      t.references :billable_item, index: true, foreign_key: true
      t.references :concession, index: true, foreign_key: true
      t.string :value

      t.timestamps null: false
    end
  end
end
