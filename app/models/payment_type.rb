class PaymentType < ActiveRecord::Base
  belongs_to :company
  
#   later validations 
  validates_presence_of :name
  
  has_many :payment_types_payments
  has_many :payments , :through => :payment_types_payments , dependent: :destroy
  
  has_and_belongs_to_many :payments
  
#   ending here ----
  
end
