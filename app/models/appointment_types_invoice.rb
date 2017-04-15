class AppointmentTypesInvoice < ActiveRecord::Base
  belongs_to :appointment_type
  belongs_to :invoice
end
