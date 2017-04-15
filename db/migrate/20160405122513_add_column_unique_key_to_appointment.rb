class AddColumnUniqueKeyToAppointment < ActiveRecord::Migration
  def change
    add_column :appointments, :unique_key, :integer
  end
end
