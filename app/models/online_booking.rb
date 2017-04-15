class OnlineBooking < ActiveRecord::Base
  belongs_to :company
  
  # attr_accessible :allow_online , :show_address , :ga_code , :min_appointment , :advance_booking_time , :min_cancel_appoint_time , :notify_by , :show_price , :hide_end_time , :req_patient_addr , :time_sel_info, :terms

  has_attached_file :logo, styles: { medium: "300x300>", thumb: "100x100>" }, default_url: "/assets/missing.png"
  validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/
  
#   later validations 
  validates_associated :company 
  validates :notify_by , presence: true ,  inclusion: { in: %w(None sms email sms_email),
    message: "%{value} is not a valid notification" }

  def online_time_period_for_appnt
    date_time = DateTime.now
    case self.advance_booking_time
      when '1h'
        return date_time + 1.hour
      when '2h'
        return date_time + 2.hours
      when '3h'
        return date_time + 3.hours
      when '4h'
        return date_time + 4.hours
      when 'tomorrow'
        return date_time + 1.day
      when '2d'
        return date_time + 2.days
    end
  end
    
  
#   ending here -----
  
end
