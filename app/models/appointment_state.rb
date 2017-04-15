class AppointmentState < ActiveRecord::Base
  belongs_to :user
  
  serialize :selected_practitioners , Array
  
end
