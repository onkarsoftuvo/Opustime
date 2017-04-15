class WaitListsAppointment < ActiveRecord::Base
  belongs_to :wait_list
  belongs_to :appointment
end
