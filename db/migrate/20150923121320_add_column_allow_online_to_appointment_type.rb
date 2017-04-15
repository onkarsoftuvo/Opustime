class AddColumnAllowOnlineToAppointmentType < ActiveRecord::Migration
  def change
    add_column :appointment_types, :allow_online, :boolean , :default=> true
  end
end
