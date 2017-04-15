class AppointmentTypesBillableItem < ActiveRecord::Base
  belongs_to :appointment_type
  belongs_to :billable_item
end
