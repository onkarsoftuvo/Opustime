module Intuit
  class OpustimeTransactionDelete < Credentials

    def initialize(object_id, object_class, token, secret, realm_id)
      super(token, secret, realm_id)
      @object_class = object_class
      @object = object_finder(object_id)
    end

    def sync_delete
      if @object_class.to_s.eql?('Invoice')
        qbo_invoice = Quickbooks::Invoice.new(@token, @secret, @realm_id)
        # check invoice on QBO
        remote_invoice_qbo_id = qbo_invoice.fetch_by_id(@object.qbo_id)
        qbo_invoice.delete_on_qbo(@object.qbo_id, @object) if remote_invoice_qbo_id.present?
      elsif @object_class.to_s.eql?('Payment')
        qbo_payment = Quickbooks::Payment.new(@token, @secret, @realm_id)
        # check payment on QBO
        remote_payment_qbo_id = qbo_payment.fetch_by_id(@object.qbo_id)
        qbo_payment.delete_on_qbo(@object.qbo_id, @object) if remote_payment_qbo_id.present?
      elsif @object_class.to_s.eql?('Expense')
        qbo_expense = Quickbooks::Bill.new(@token, @secret, @realm_id)
        # check expense on QBO
        remote_expense_qbo_id = qbo_expense.fetch_by_id(@object.qbo_id)
        qbo_expense.delete_on_qbo(@object.qbo_id, @object) if remote_expense_qbo_id.present?
      end

    end

    private

    def object_finder(object_id)
      if @object_class.to_s.eql?('Invoice')
        Invoice.find_by_id(object_id)
      elsif @object_class.to_s.eql?('Payment')
        Payment.find_by_id(object_id)
      elsif @object_class.to_s.eql?('Expense')
        Expense.find_by_id(object_id)
      end
    end

    handle_asynchronously :sync_delete, :queue => 'Intuit'

  end
end
