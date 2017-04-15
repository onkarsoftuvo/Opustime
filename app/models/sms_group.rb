class SmsGroup < ActiveRecord::Base
  has_many :sms_group_countries, :dependent => :destroy
  has_many :sms_plans, :dependent => :destroy
end
