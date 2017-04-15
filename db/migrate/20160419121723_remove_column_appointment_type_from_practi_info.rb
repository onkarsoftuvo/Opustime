class RemoveColumnAppointmentTypeFromPractiInfo < ActiveRecord::Migration
  def change
    remove_column :practi_infos , :appointment_services
  end
end
