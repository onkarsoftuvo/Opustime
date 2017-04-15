class CreateWaitListsUsers < ActiveRecord::Migration
  def change
    create_table :wait_lists_users do |t|
      t.references :wait_list, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.boolean :is_selected , :default=> false

      t.timestamps null: false
    end
  end
end
