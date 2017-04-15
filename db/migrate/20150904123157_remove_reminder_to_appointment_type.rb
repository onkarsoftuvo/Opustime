class RemoveReminderToAppointmentType < ActiveRecord::Migration
  def change
     remove_column :appointment_types , :reminder
  end
end
