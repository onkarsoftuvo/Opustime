class TreatmentNotesTemplateNote < ActiveRecord::Base
  belongs_to :treatment_note
  belongs_to :template_note
end
