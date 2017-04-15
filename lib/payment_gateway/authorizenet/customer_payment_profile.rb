module PaymentGateway
  module Authorizenet
    class CustomerPaymentProfile < Authorizenet::Connection
      include AuthorizeNet::API

      def create(customer, customer_profile_id, credit_card)

        request = CreateCustomerPaymentProfileRequest.new
        payment = PaymentType.new(CreditCardType.new(credit_card.number, credit_card_expiry_date(credit_card.expiry_month, credit_card.expiry_year), credit_card.cvv))

        profile = CustomerPaymentProfileType.new(nil, nil, payment, nil, nil)
        profile.billTo = NameAndAddressType.new(customer.first_name, customer.last_name, customer.try(:company).try(:name), customer.try(:address), customer.try(:city), customer.try(:state), customer.try(:postal_code), customer.try(:country))

        request.paymentProfile = profile
        request.customerProfileId = customer_profile_id
        response = @transaction.create_customer_payment_profile(request)

        if response.messages.resultCode == MessageTypeEnum::Ok
          Logs.update_transaction_log(customer, response.customerPaymentProfileId, 'create customer payment profile', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Payment Profile')
          return response.customerPaymentProfileId, nil
        else
          Logs.update_transaction_log(customer, response.customerPaymentProfileId, 'create customer payment profile', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Payment Profile')
          response.messages.messages[0].code.to_s.eql?('E00039') ? (return customer.authorizenet_payment_profile_id, response.messages.messages[0].text) : (return nil, response.messages.messages[0].text)

          return nil
        end

      end

      def update(customer, customer_payment_profile_id, customer_profile_id, credit_card)

        request = UpdateCustomerPaymentProfileRequest.new
        payment = PaymentType.new(CreditCardType.new(credit_card.number, credit_card_expiry_date(credit_card.expiry_month, credit_card.expiry_year), credit_card.cvv))

        profile = CustomerPaymentProfileExType.new(nil, nil, payment, nil, nil)
        profile.billTo = NameAndAddressType.new(customer.first_name, customer.last_name, customer.try(:company).try(:name), customer.try(:address), customer.try(:city), customer.try(:state), customer.try(:postal_code), customer.try(:country))
        profile.customerPaymentProfileId = customer_payment_profile_id

        request.paymentProfile = profile
        request.customerProfileId = customer_profile_id
        profile.customerPaymentProfileId = customer_payment_profile_id
        response = @transaction.update_customer_payment_profile(request)

        if response.messages.resultCode == MessageTypeEnum::Ok
          Logs.update_transaction_log(customer, request.paymentProfile.customerPaymentProfileId, 'update customer payment profile', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Payment Profile')
          return request.paymentProfile.customerPaymentProfileId
        else
          Logs.update_transaction_log(customer, request.paymentProfile.customerPaymentProfileId, 'update customer payment profile', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Payment Profile')
          return nil
        end


      end

      def delete(customer, customer_profile_id, customer_payment_profile_id)

        request = DeleteCustomerPaymentProfileRequest.new
        request.customerProfileId = customer_profile_id
        request.customerPaymentProfileId = customer_payment_profile_id
        response = @transaction.delete_customer_payment_profile(request)

        if response.messages.resultCode == MessageTypeEnum::Ok
          Logs.update_transaction_log(customer, request.customerPaymentProfileId, 'delete customer payment profile', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Payment Profile')
          return request.customerPaymentProfileId
        else
          Logs.update_transaction_log(customer, request.customerPaymentProfileId, 'delete customer payment profile', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Payment Profile')
          return nil
        end

      end


      def credit_card_expiry_date(month, year)
        year.to_s+'-'+month.to_s
      end

    end
  end
end