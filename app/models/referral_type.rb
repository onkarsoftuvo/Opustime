class ReferralType < ActiveRecord::Base
  belongs_to :company
  
  has_many :referral_type_subcats, :dependent => :destroy 

  accepts_nested_attributes_for :referral_type_subcats , :reject_if => lambda { |a| a[:sub_name].blank? }, :allow_destroy => true
  

  scope :specific_attributes , ->{ select("id, referral_source")}
  scope :active_referral_type, ->{ where(["status IN ('inactive','active')"])}

  validates :referral_source , presence: true 
  
  validates_associated :referral_type_subcats

end
