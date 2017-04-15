class AppointmentsInvoice < ActiveRecord::Base
  belongs_to :appointment
  belongs_to :invoice
end
