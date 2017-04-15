class AppointmentTypesTemplateNote < ActiveRecord::Base
  belongs_to :appointment_type
  belongs_to :template_note
end
