class RemoveColumnMedicalAlertToPatient < ActiveRecord::Migration
  def change
    remove_column :patients , :medical_alert
  end
end
