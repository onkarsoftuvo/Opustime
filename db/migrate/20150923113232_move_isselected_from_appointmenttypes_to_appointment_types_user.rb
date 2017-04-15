class MoveIsselectedFromAppointmenttypesToAppointmentTypesUser < ActiveRecord::Migration
  def change
    remove_column :appointment_types , :is_selected
    add_column :appointment_types_users , :is_selected , :boolean
    add_column :appointment_types_users , :practi_name , :string
    
  end
end
