class AddAppointmentservicesToPractiInfo < ActiveRecord::Migration
  def change
    add_column :practi_infos , :appointment_services , :text
  end
end
