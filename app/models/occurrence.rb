class Occurrence < ActiveRecord::Base
  belongs_to :appointment
  belongs_to :childappointment , :class_name=> "Appointment"
end
