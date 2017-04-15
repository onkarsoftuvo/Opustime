class AddColumnsToAppointment < ActiveRecord::Migration
  def change
    add_column :appointments, :rescheduler_id, :integer
    add_column :appointments, :rescheduler_type, :string
  end
end
