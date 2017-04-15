class CreateAppointmentTypesAppointments < ActiveRecord::Migration
  def change
    create_table :appointment_types_appointments  do |t|
      t.references :appointment_type, index: true, foreign_key: true
      t.references :appointment, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
