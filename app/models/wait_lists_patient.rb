class WaitListsPatient < ActiveRecord::Base
  belongs_to :patient
  belongs_to :wait_list
  
  validates :patient_id , :presence=> true
  # validates :wait_list_id , :presence=> true
end
