class AppointmentTypesUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :appointment_type
end
