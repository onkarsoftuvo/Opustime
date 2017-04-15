class ChangeDatatypeofShowAddressToOnlineBooking < ActiveRecord::Migration
  def change
    change_column :online_bookings, :show_address , :text
  end
end
