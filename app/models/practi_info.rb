class PractiInfo < ActiveRecord::Base
  serialize :appointment_services , Array
  
  belongs_to :user ,  :autosave => true

  has_and_belongs_to_many :businesses , :dependent=> :destroy
  
  # has_many :practi_avails , :dependent=> :destroy

  # has_many :practi_breaks , :through=> :practi_avails , :dependent=> :destroy
 
  has_many :practitioner_avails , :dependent=> :destroy
  
  accepts_nested_attributes_for :practitioner_avails , :allow_destroy => true
  # validates_associated :practitioner_avails
  # validates :practitioner_avails , :presence =>true , :allow_nil=> true

  has_many :days , :through=> :practitioner_avails , :dependent=> :destroy
  
# nested attributes for practi_refers  model begin here ---
  has_many :practi_refers   ,:dependent=> :destroy

  accepts_nested_attributes_for :practi_refers , :allow_destroy => true
  # validates_associated :practi_refers
  # validates :practi_refers , :presence=> true , :allow_nil=> true
# ending here 
  
# later validations 
  # validates_associated :practi_refers  
  validates :cancel_time    , :numericality => { :only_integer => true , :greater_than_or_equal_to => 0 , :less_than_or_equal_to =>14 }, :allow_nil=> true
  
#   ending here -----
  
end
