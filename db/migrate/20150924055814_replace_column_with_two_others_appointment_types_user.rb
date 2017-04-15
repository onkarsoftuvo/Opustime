class ReplaceColumnWithTwoOthersAppointmentTypesUser < ActiveRecord::Migration
  def change
    remove_column :appointment_types_users , :practi_name
    add_column :appointment_types_users , :first_name , :string
    add_column :appointment_types_users , :last_name , :string 
  end
end
