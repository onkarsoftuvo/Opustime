class AddColumnAppntStatusToAppointment < ActiveRecord::Migration
  def change
    add_column :appointments, :appnt_status, :boolean
  end
end
