class AddColumnsCancellerToAppointment < ActiveRecord::Migration
  def change
    add_column :appointments, :canceller_id, :integer
    add_column :appointments, :canceller_type, :string
  end
end
