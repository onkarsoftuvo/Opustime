class AddCheckedToAppointmentType < ActiveRecord::Migration
  def change
    add_column :appointment_types, :is_selected, :boolean , :default => false
  end
end
