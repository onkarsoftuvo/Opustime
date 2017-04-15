class PractiAvail < ActiveRecord::Base
  serialize :cust_break , Array
  
  belongs_to :business
  has_one :practi_info , :through=> :business , :dependent=> :destroy
  has_many :practi_breaks , :dependent=> :destroy
   
  accepts_nested_attributes_for :practi_breaks
  
#   later validations 
  # validates :start_hr , :end_hr , presence: true ,
            # numericality: { only_integer: true , :greater_than_or_equal_to=> 0 , :less_than_or_equal_to => 23 } 
#             
   # validates :start_min , :end_min , presence: true ,
             # numericality: { only_integer: true , :greater_than_or_equal_to=> 0 , :less_than_or_equal_to => 60 }
#             
  # validates :day_name , presence: true , inclusion: { in: %w(sunday monday tuesday wednesday thursday friday saturday),
    # message: "%{value} is not a valid  day" }
    
#  ending here ---    
    
end
