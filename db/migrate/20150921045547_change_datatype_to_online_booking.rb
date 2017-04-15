class ChangeDatatypeToOnlineBooking < ActiveRecord::Migration
  def change
    change_column :online_bookings , :min_appointment , :string
    change_column :online_bookings , :advance_booking_time , :string
    change_column :online_bookings, :min_cancel_appoint_time , :string
    change_column :online_bookings, :show_price , :boolean , :default=> false
    change_column :online_bookings, :hide_end_time , :boolean , :default=> false
    change_column :online_bookings, :req_patient_addr , :boolean , :default=> false
    change_column :online_bookings, :allow_online , :boolean , :default=> false
  end
end
