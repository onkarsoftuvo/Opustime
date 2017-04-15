class PractitionerAvail < ActiveRecord::Base
  belongs_to :practi_info
  
  has_many :days , :dependent=> :destroy
  
  accepts_nested_attributes_for :days 
  validates_associated :days
  # validates :days, :presence=> true , :allow_nil=> true
  
  has_many :practitioner_breaks , :through=> :days , :dependent=> :destroy
  
  
  
end
