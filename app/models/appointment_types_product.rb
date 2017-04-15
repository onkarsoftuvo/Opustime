class AppointmentTypesProduct < ActiveRecord::Base
  belongs_to :appointment_type
  belongs_to :product
end
