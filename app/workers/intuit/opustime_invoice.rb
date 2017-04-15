module Intuit
  class OpustimeInvoice < Credentials

    def initialize(invoice_id, token, secret, realm_id, qbo_credential_id)
      super(token,secret,realm_id)
      # find invoice form db
      @invoice = Invoice.find_by_id(invoice_id)
      # get company qbo credential object
      @qbo_credential = QuickBookInfo.find_by_id(qbo_credential_id)
    end

    def sync
      # create Quickbooks invoice object
      qbo_invoice = Quickbooks::Invoice.new(@token, @secret, @realm_id)
      # check invoice on QBO
      remote_qbo_id = qbo_invoice.fetch_by_id(@invoice.qbo_id)
      # send data on Quickbooks
      remote_qbo_id.present? ? qbo_invoice.update_on_qbo(@invoice.qbo_id, @invoice, @token, @secret, @realm_id, @qbo_credential) : qbo_invoice.create_on_qbo(@invoice, @token, @secret, @realm_id, @qbo_credential)
    end

    handle_asynchronously :sync, :queue => 'Intuit'

  end
end
