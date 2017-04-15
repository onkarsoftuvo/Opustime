class RecallType < ActiveRecord::Base
  belongs_to :company
  
 # later validations

  validates :name , presence: true  
  # validates :period_val ,  numericality: { only_integer: true , :greater_than_or_equal_to=> 0 , :less_than_or_equal_to => 100 }

 # ending here ---- 
 
 has_many :recall_types_recalls , :dependent => :destroy
 has_many :recalls , :through=> :recall_types_recalls , :dependent=> :destroy    

end
