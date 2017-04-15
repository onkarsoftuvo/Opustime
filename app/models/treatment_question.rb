class TreatmentQuestion < ActiveRecord::Base
  belongs_to :treatment_section
  
  has_many :treatment_quest_choices , :dependent => :destroy
  has_many :treatment_answers , :through => :treatment_quest_choices , :dependent => :destroy 
  
  accepts_nested_attributes_for :treatment_quest_choices , :allow_destroy => true
  
end
