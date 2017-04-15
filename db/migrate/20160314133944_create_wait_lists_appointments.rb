class CreateWaitListsAppointments < ActiveRecord::Migration
  def change
    create_table :wait_lists_appointments do |t|
      t.references :wait_list, index: true, foreign_key: true
      t.references :appointment, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
