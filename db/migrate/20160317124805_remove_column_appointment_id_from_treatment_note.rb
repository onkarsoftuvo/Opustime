class RemoveColumnAppointmentIdFromTreatmentNote < ActiveRecord::Migration
  def change
    remove_column :treatment_notes , :appointment_id
  end
end
