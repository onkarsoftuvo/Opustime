class AddAttachmentLogoToOnlineBookings < ActiveRecord::Migration
  def self.up
    change_table :online_bookings do |t|
      t.attachment :logo
    end
  end

  def self.down
    remove_attachment :online_bookings, :logo
  end
end
