class MedicalAlert < ActiveRecord::Base
  belongs_to :patient
  validates :alertName , :length => { :minimum => 1 }
end
