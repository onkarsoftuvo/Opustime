class SetDefaultValueAppointmentTypesUser < ActiveRecord::Migration
  def change
    change_column :appointment_types_users ,:is_selected , :boolean , :default=> false 
  end
end
