class CreateWaitListsBusinesses < ActiveRecord::Migration
  def change
    create_table :wait_lists_businesses do |t|
      t.references :wait_list, index: true, foreign_key: true
      t.references :business, index: true, foreign_key: true
      t.boolean :is_selected , :default=> false

      t.timestamps null: false
    end
  end
end
