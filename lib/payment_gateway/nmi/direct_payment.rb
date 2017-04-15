module PaymentGateway
  module NMI
    class DirectPayment < Service
      attr_accessor :amount

      def initialize(customer_address, amount, company, plan, credit_card=nil)
        super()
        @billing = {}
        @shipping = {}
        @order = {}
        @amount = amount
        @credit_card = credit_card if credit_card.present?
        @company = company
        @payment_type = plan.class.to_s.eql?('Plan') ? 'Subscription Plan' : 'Sms Credit' if plan.present?
        @plan = plan if plan.present?
        @customer_vault_id = company.vault_id
        # set customer billing address
        @billing['firstname'] = customer_address.firstname
        @billing['lastname'] = customer_address.lastname
        @billing['company'] = customer_address.company
        @billing['address1'] = customer_address.address1
        @billing['address2'] = customer_address.address2
        @billing['city'] = customer_address.city
        @billing['state'] = customer_address.state
        @billing['zip'] = customer_address.zip
        @billing['country'] = customer_address.country
        @billing['phone'] = customer_address.phone
        @billing['fax'] = customer_address.fax
        @billing['email'] = customer_address.email
        @billing['website'] = customer_address.website
        # set customer shipping address
        @shipping['firstname'] = customer_address.firstname
        @shipping['lastname'] = customer_address.lastname
        @shipping['company'] = customer_address.company
        @shipping['address1'] = customer_address.address1
        @shipping['address2'] = customer_address.address2
        @shipping['city'] = customer_address.city
        @shipping['state'] = customer_address.state
        @shipping['zip'] = customer_address.zip
        @shipping['country'] = customer_address.country
        @shipping['email'] = customer_address.email
      end


      def auth_and_capture

        query = ''
        # Login Information
        query = query + 'username=' + URI.escape(@login['username']) + '&'
        query += 'password=' + URI.escape(@login['password']) + '&'
        query += 'customer_vault_id=' + URI.escape(@customer_vault_id) + '&'
        query += 'amount=' + URI.escape("%.2f" %@amount) + '&'
        # Billing Information
        @billing.each do |key, value|
          query += key +'=' + URI.escape(value) + '&' if value.present?
        end
        # Shipping Information
        @shipping.each do |key, value|
          query += key +'=' + URI.escape(value) + '&' if value.present?
        end

        query += 'type=sale'
        gateway_response = doPost(query)
        # generate payment log
        @plan.class.to_s.eql?('Plan') ?
            PaymentGateway::NMI::TransactionLog.new(gateway_response, @company).plan_payment_transaction_log(@amount, @plan) :
            PaymentGateway::NMI::TransactionLog.new(gateway_response, @company).sms_payment_transaction_log(@amount, @plan)
        SubscriptionMailer.sidekiq_delay(:queue => 'subscription').payment_deduction(@company.id, @amount) if gateway_response['response'].to_s.eql?('1')
        return gateway_response
      end


      def initial_payment
        query = ''
        # Login Information
        query = query + 'username=' + URI.escape(@login['username']) + '&'
        query += 'password=' + URI.escape(@login['password']) + '&'
        query += 'ccnumber=' + URI.escape(@credit_card.number) + '&'
        query += 'ccexp=' + URI.escape(@credit_card.expiry_month.to_s+@credit_card.expiry_year.to_s.slice!(2..3)) + '&'
        query += 'cvv=' + URI.escape(@credit_card.cvv) + '&'
        query += 'amount=' + URI.escape("%.2f" %@amount) + '&'
        # Billing



        @billing.each do |key, value|
          query += key +'=' + URI.escape(value) + '&' if value.present?
        end
        # Shipping Information
        @shipping.each do |key, value|
          query += key +'=' + URI.escape(value) + '&' if value.present?
        end

        query += 'type=validate'
        gateway_response = doPost(query)
        # generate payment log
        PaymentGateway::NMI::TransactionLog.new(gateway_response, @company).card_registration_charges_log(@amount)
        return gateway_response
      end

    end
  end
end