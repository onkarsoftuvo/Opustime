class AppointmentTypesWaitList < ActiveRecord::Base
  belongs_to :appointment_type
  belongs_to :wait_list
  
  validates :appointment_type_id , :presence=> true
  # validates :wait_list_id , :presence=> true
end
