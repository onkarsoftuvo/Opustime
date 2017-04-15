class TreatmentQuestChoice < ActiveRecord::Base
  belongs_to :treatment_question
  
  has_one :treatment_answer ,  :dependent => :destroy
  
  accepts_nested_attributes_for :treatment_answer , :allow_destroy => true
  
end
