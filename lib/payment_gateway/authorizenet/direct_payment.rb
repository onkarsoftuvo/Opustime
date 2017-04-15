module PaymentGateway
  module Authorizenet
    class DirectPayment < Authorizenet::Connection
      include AuthorizeNet::API

      def process(customer, customer_profile_id, customer_payment_profile_id)
        request = CreateTransactionRequest.new
        request.transactionRequest = TransactionRequestType.new
        request.transactionRequest.amount = @price
        request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
        request.transactionRequest.profile = CustomerProfilePaymentType.new
        request.transactionRequest.profile.customerProfileId = customer_profile_id
        request.transactionRequest.profile.paymentProfile = PaymentProfile.new(customer_payment_profile_id)

        response = @transaction.create_transaction(request)

        if response != nil
          if response.messages.resultCode == MessageTypeEnum::Ok
            if response.transactionResponse != nil && response.transactionResponse.messages != nil
              Logs.update_transaction_log(customer, response.transactionResponse.transId, 'apply direct payment to customer profile', response.transactionResponse.responseCode, response.transactionResponse.messages.messages[0].description, false, 'SMS Payment', @price)
              return response.transactionResponse.transId, response.transactionResponse.messages.messages[0].description, response.transactionResponse.responseCode
            else
              puts 'Transaction Failed'
              if response.transactionResponse.errors != nil
                Logs.update_transaction_log(customer, response.transactionResponse.transId, 'apply direct payment to customer profile', response.transactionResponse.errors.errors[0].errorCode, response.transactionResponse.errors.errors[0].errorText, true, 'SMS Payment', @price)
                return nil, response.transactionResponse.errors.errors[0].errorText
              end
              raise 'Failed to charge customer profile'
            end
          else
            puts 'Transaction Failed'
            if response.transactionResponse != nil && response.transactionResponse.errors != nil
              Logs.update_transaction_log(customer, response.transactionResponse.transId, 'apply direct payment to customer profile', response.transactionResponse.errors.errors[0].errorCode, response.transactionResponse.errors.errors[0].errorText, true, 'SMS Payment', @price)
              return nil, response.transactionResponse.errors.errors[0].errorText
            else
              Logs.update_transaction_log(customer, response.transactionResponse.transId, 'apply direct payment to customer profile', response.messages.messages[0].code, response.messages.messages[0].text, true, 'SMS Payment', @price)
              return nil, response.messages.messages[0].text
            end
            raise 'Failed to charge customer profile'
          end
        else
          puts 'Response is null'
          raise 'Failed to charge customer profile.'
          return nil, 'Failed to charge customer profile'
        end
      end
    end
  end
end