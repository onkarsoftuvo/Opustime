class CreateOnlineBookings < ActiveRecord::Migration
  def change
    create_table :online_bookings do |t|
      t.boolean :allow_online
      t.boolean :show_address
      t.text :ga_code
      t.integer :min_appointment
      t.integer :advance_booking_time
      t.integer :min_cancel_appoint_time
      t.string :notify_by
      t.boolean :show_price
      t.boolean :hide_end_time
      t.boolean :req_patient_addr
      t.text :time_sel_info
      t.text :terms
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
