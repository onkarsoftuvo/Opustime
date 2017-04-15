class TreatmentNotesAppointment < ActiveRecord::Base
  belongs_to :treatment_note
  belongs_to :appointment
end
