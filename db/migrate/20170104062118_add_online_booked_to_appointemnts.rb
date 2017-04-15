class AddOnlineBookedToAppointemnts < ActiveRecord::Migration
  def change
    add_column :appointments,:online_booked,:boolean, default: false
  end
end
