class AddReminderConfirmemailToAppointmentType < ActiveRecord::Migration
  def change
    add_column :appointment_types , :confirm_email , :boolean
    add_column :appointment_types , :send_reminder , :boolean
  end
end
