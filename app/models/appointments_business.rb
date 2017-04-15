class AppointmentsBusiness < ActiveRecord::Base
  belongs_to :appointment
  belongs_to :business
  
  # validates :appointment_id , :presence=> true
  validates :business_id , :presence=> true
end
