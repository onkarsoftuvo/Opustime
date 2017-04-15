class InvoicesPayment < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :payment
  
  validate :payment_should_noe_be_greater_than_invoice_outstanding #, :payment_should_noe_be_greater_than_paid_money
  
  scope :active_invoices_payments, ->{ where(status: true)}
  
  after_save :set_close_date_for_invoice
  
  before_save do |invoice_payment| 
    invoice_payment.amount = invoice_payment.amount.to_f if invoice_payment.amount.nil?
  end

  
  
  def payment_should_noe_be_greater_than_invoice_outstanding
    unless (amount.nil? && credit_amount.nil?)
      if (amount.to_f + credit_amount.to_f) > self.invoice.invoice_amount.to_f
        errors.add(:is, ' not allowed. exceeding of invoice outstanding balance.')
      end
      return false if errors.count > 0
    end
  end 
  
  def payment_should_noe_be_greater_than_paid_money
    paid_amount = self.payment.get_paid_amount
    if (amount.to_f > paid_amount)
      errors.add(:is, " allocations exceed the amount of the payment.")
    end
    return false if errors.count > 0
  end
  
  def set_close_date_for_invoice
    invoice = self.invoice 
    if invoice.calculate_outstanding_balance == 0 && invoice.status== true
      invoice.update_column(:close_date,Date.today)
      appnt = nil
      appnt_inv = AppointmentsInvoice.find_by(invoice_id: invoice.id)
      appnt = appnt_inv.appointment if appnt_inv.present?
      if appnt.present?
        appnt.update_column(:appnt_status, 1)
      end
    end
  end

  
  
  private 
  
  def associated_payment_status?
    return self.payment.status
  end
  
  
end