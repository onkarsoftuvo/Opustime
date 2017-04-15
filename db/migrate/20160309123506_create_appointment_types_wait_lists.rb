class CreateAppointmentTypesWaitLists < ActiveRecord::Migration
  def change
    create_table :appointment_types_wait_lists do |t|
      t.references :appointment_type, index: true, foreign_key: true
      t.references :wait_list, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
