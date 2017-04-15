class WaitListsBusiness < ActiveRecord::Base
  belongs_to :wait_list
  belongs_to :business
  
  # validates :wait_list_id , :presence=> true
  validates_presence_of :business_id , :message=> "must be seletced at least one"
end
