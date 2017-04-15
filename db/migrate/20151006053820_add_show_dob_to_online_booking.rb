class AddShowDobToOnlineBooking < ActiveRecord::Migration
  def change
    add_column :online_bookings , :show_dob , :boolean , :default=> false
  end
end
