class AddColumnPatientArriveToAppointment < ActiveRecord::Migration
  def change
    add_column :appointments , :patient_arrive , :boolean 
  end
end
