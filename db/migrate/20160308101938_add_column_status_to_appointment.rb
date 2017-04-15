class AddColumnStatusToAppointment < ActiveRecord::Migration
  def change
    add_column :appointments, :status, :boolean , default: true
  end
end
