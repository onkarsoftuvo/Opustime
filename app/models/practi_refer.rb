class PractiRefer < ActiveRecord::Base
  belongs_to :practi_info 
  
#  later validations   
 # validates :ref_type, length: { maximum: 250 ,
                        # too_long: "%{count} characters is the maximum allowed" } , :allow_nil=> true
#   
 # validates :number , numericality: true ,
             # length: { maximum: 10 ,
              # too_long: "%{count} characters is the maximum allowed" }  , :allow_nil=> true

 # ending here ---  
  
end
