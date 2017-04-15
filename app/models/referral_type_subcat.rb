class ReferralTypeSubcat < ActiveRecord::Base
  belongs_to :referral_type
  
  validates :sub_name , presence: true
  
end
