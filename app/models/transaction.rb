class Transaction < ActiveRecord::Base
  belongs_to :company
  belongs_to :sms_plan
  belongs_to :plan
  serialize :response,JSON
end
