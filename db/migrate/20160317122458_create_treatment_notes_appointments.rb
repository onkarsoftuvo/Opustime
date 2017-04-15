class CreateTreatmentNotesAppointments < ActiveRecord::Migration
  def change
    create_table :treatment_notes_appointments do |t|
      t.references :treatment_note, index: true, foreign_key: true
      t.references :appointment, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
