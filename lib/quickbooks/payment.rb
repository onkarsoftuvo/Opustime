module Quickbooks
  class Payment < Quickbooks::Connection

    # Set QBO payment model attributes
    def set_qbo_attributes_hash(customer, payment)

      linked_invoices_payments = payment.invoices_payments.active_invoices_payments
      total_amount = payment.get_paid_amount
      line = []

      if linked_invoices_payments.size > 0
        linked_invoices_payments.each do |invoice_payment|
          line.push({
                        :Amount => "#{invoice_payment.amount}",
                        :LinkedTxn => [
                            {
                                :TxnId => "#{invoice_payment.invoice.qbo_id}",
                                :TxnType => 'Invoice'
                            }]
                    })
        end

      end

      {
          :CustomerRef =>
              {
                  :value => "#{customer.qbo_id}",
                  :name => "#{customer.full_name}"
              },
          :TotalAmt => total_amount,
          :Line => line,
          :PaymentRefNum => "#{payment.id}"
      }
    end

    # Fetch qbo remote payment object
    def fetch_by_id(qbo_id)
      begin
        @qbo_api.get(:payment, qbo_id)['Id'] rescue nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end

    end

    # Create payment object on QBO
    def create_on_qbo(customer, payment)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(customer.company)
        response = @qbo_api.create(:payment, payload: JSON.parse(set_qbo_attributes_hash(customer, payment).to_json))
        payment.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(payment, 'Successfully created on QBO', 'create', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(payment, error.message, 'create', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(payment, error.message, 'create', true, logs)
      end

    end

    # Update payment object on QBO
    def update_on_qbo(qbo_id, customer, payment)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(customer.company)
        response = @qbo_api.update(:payment, id: qbo_id, payload: JSON.parse(set_qbo_attributes_hash(customer, payment).to_json))
        payment.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(payment, 'Successfully updated on QBO', 'update', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(payment, error.message, 'update', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(payment, error.message, 'update', true, logs)
      end

    end

    # Delete payment object on QBO
    def delete_on_qbo(qbo_id, payment)
      begin
        logs = Quickbooks::Logs.new(payment.patient.company)
        response = @qbo_api.delete(:payment, id: qbo_id)
        if response['status'].to_s.eql?('Deleted')
          logs.update_success_log(payment, 'Successfully deleted on QBO', 'delete', false, logs)
        else
          logs.update_success_log(payment, 'Not deleted on QBO', 'delete', false, logs)
        end
      rescue Faraday::ConnectionFailed
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(payment, error.message, 'delete', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(payment, error.message, 'delete', true, logs)
      end
    end

  end
end