class ChangeDataTypeDurationTimeToAppointmentType < ActiveRecord::Migration
  def change
    change_column :appointment_types , :duration_time , :string
  end
end
