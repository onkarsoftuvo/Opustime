class PaymentTypesPayment < ActiveRecord::Base
  belongs_to :payment_type
  belongs_to :payment
  
  validates :amount, :presence=> true ,:numericality => { :greater_than => 0}
  
  # after_create :set_credit_amount_for_patient
  # before_update :set_credit_amount_for_patient_on_update , :if => :associated_payment_status?
  
  scope :active_payment_types_payments, ->{ where(status: true)}
  
  # def set_credit_amount_for_patient
    # patient = self.payment.patient
    # patient_credit_amount = patient.credit_amount.to_f
    # patient.update_attributes(credit_amount: (patient_credit_amount + self.amount.to_f) )  
  # end
#   
  # def set_credit_amount_for_patient_on_update
    # debugger
    # patient = self.payment.patient
    # patient_credit_amount = patient.credit_amount.to_f
    # amount_diff = self.amount.to_f - self.amount_was.to_f    
    # patient.update_attributes(credit_amount: (patient_credit_amount + amount_diff) )
  # end
  
  # private 
#   
  # def associated_payment_status?
    # return self.payment.status  
  # end
end
