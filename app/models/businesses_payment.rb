class BusinessesPayment < ActiveRecord::Base
  belongs_to :business , :inverse_of=> :businesses_payment
  belongs_to :payment , :inverse_of=> :businesses_payment
end
