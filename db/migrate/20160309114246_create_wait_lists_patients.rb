class CreateWaitListsPatients < ActiveRecord::Migration
  def change
    create_table :wait_lists_patients do |t|
      t.references :patient, index: true, foreign_key: true
      t.references :wait_list, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
