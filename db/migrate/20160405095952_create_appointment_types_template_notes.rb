class CreateAppointmentTypesTemplateNotes < ActiveRecord::Migration
  def change
    create_table :appointment_types_template_notes do |t|
      t.references :appointment_type, index: true, foreign_key: true
      t.references :template_note, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
