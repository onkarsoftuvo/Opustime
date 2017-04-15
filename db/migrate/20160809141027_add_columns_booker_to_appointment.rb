class AddColumnsBookerToAppointment < ActiveRecord::Migration
  def change
    add_column :appointments, :booker_id, :integer
    add_column :appointments, :booker_type, :string
  end
end
