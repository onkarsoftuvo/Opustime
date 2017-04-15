class TreatmentSection < ActiveRecord::Base
  belongs_to :treatment_note
  
  has_many :treatment_questions , :dependent => :destroy
  accepts_nested_attributes_for :treatment_questions , :allow_destroy => true
end
