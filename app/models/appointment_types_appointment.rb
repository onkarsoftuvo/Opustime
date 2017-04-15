class AppointmentTypesAppointment < ActiveRecord::Base
  audited associated_with: :appointment
  
  belongs_to :appointment_type
  belongs_to :appointment
  
  validates :appointment_type_id , :presence=> true
  # validates :appointment_id , :presence=> true
  
  
end
