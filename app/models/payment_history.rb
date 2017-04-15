class PaymentHistory < ActiveRecord::Base
  belongs_to :company 
  belongs_to :paymentable, :polymorphic => true
end
