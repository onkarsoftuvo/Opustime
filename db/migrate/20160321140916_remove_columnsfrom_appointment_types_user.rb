class RemoveColumnsfromAppointmentTypesUser < ActiveRecord::Migration
  def change
    remove_column :appointment_types_users , :first_name
    remove_column :appointment_types_users , :last_name
    remove_column :appointment_types_users , :is_selected
  end
end
