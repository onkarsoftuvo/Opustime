class WaitListsUser < ActiveRecord::Base
  belongs_to :wait_list
  belongs_to :user
  
  # validates :wait_list_id , :presence=> true
  validates :user_id , :presence=> true 
end
