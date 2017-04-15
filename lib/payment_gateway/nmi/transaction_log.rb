module PaymentGateway
  module NMI
    class TransactionLog
      # we are using multiple transaction type codes and details are given below
      # 1- CV (Customer Vault)
      # 2- SP (SMS Payment)
      # 3- ISP (Initial Subscription Payment)
      # 4- SA (Subscription Added)
      # 5- SC (Subscription Cancelled)
      # 6- CRC (Card Registration Charge)

      def initialize(response, company)
        @response = response
        @company = company
      end

      def customer_vault_log
        error_status = @response['response'].to_s.eql?('1') ? false : true
        Transaction.create(:company => @company, :response => @response, :response_id => @response['customer_vault_id'], :response_code => @response['response_code'], :response_message => @response['responsetext'], :error_status => error_status, :transaction_type => 'CV')
      end


      def card_registration_charges_log(amount)
        error_status = @response['response'].to_s.eql?('1') ? false : true
        Transaction.create(:company => @company, :response => @response, :response_id => @response['transactionid'], :response_code => @response['response_code'], :response_message => @response['responsetext'], :error_status => error_status, :amount => amount, :transaction_type => 'CRC')
      end

      def sms_payment_transaction_log(amount, sms_plan)
        error_status = @response['response'].to_s.eql?('1') ? false : true
        Transaction.create(:company => @company, :response => @response, :sms_plan => sms_plan, :response_id => @response['transactionid'], :response_code => @response['response_code'], :response_message => @response['responsetext'], :error_status => error_status, :amount => amount, :transaction_type => 'SP')
      end

      def plan_payment_transaction_log(amount, plan)
        error_status = @response['response'].to_s.eql?('1') ? false : true
        Transaction.create(:company => @company, :response => @response, :plan => plan, :response_id => @response['transactionid'], :response_code => @response['response_code'], :response_message => @response['responsetext'], :error_status => error_status, :amount => amount, :transaction_type => 'ISP')
      end

      def add_subscription_transaction_log(amount, plan)
        error_status = @response['response'].to_s.eql?('1') ? false : true
        Transaction.create(:company => @company, :response => @response, :plan => plan, :response_id => @response['transactionid'], :response_code => @response['response_code'], :response_message => @response['responsetext'], :error_status => error_status, :amount => amount, :transaction_type => 'SA')
      end

      def cancel_subscription_transaction_log(amount, plan_id)
        error_status = @response['response'].to_s.eql?('1') ? false : true
        Transaction.create(:company => @company, :response => @response, :response_id => @response['transactionid'], :plan_id => plan_id, :amount => amount, :response_code => @response['response_code'], :response_message => @response['responsetext'], :error_status => error_status, :transaction_type => 'SC')
      end


    end
  end
end