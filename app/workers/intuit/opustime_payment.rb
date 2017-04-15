module Intuit
  class OpustimePayment < Credentials

    def initialize(payment_id, token, secret, realm_id)
      super(token,secret,realm_id)
      @payment = Payment.find_by_id(payment_id)
    end

    def sync
      # create Quickbooks payment object
      qbo_payment = Quickbooks::Payment.new(@token, @secret, @realm_id)
      # check payment on qbo
      remote_qbo_id = qbo_payment.fetch_by_id(@payment.qbo_id)
      # send data on Quickbooks
      remote_qbo_id.present? ? qbo_payment.update_on_qbo(@payment.qbo_id, @payment.patient, @payment) : qbo_payment.create_on_qbo(@payment.patient, @payment)
    end

    handle_asynchronously :sync, :queue => 'Intuit'

  end
end

