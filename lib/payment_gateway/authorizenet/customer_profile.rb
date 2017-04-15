module PaymentGateway
  module Authorizenet
    class CustomerProfile < Authorizenet::Connection
      include AuthorizeNet::API

      # create customer profile on Authorize.net
      def create(customer)
        request = CreateCustomerProfileRequest.new
        request.profile = CustomerProfileType.new(customer.id, "#{customer.try(:full_name)}", customer.try(:email), nil, nil)
        response = @transaction.create_customer_profile(request)
        if response.messages.resultCode == MessageTypeEnum::Ok
          Logs.update_transaction_log(customer, response.customerProfileId, 'create customer profile', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Customer Profile')
          return response.customerProfileId, nil
        else
          Logs.update_transaction_log(customer, response.customerProfileId, 'create customer profile', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Customer Profile')
          response.messages.messages[0].code.to_s.eql?('E00039') ? (return customer.authorizenet_profile_id, response.messages.messages[0].text) : (return nil, response.messages.messages[0].text)
        end
      end

      # edit customer profile on Authorize.net
      def update(customer, customer_profile_id)
        request = UpdateCustomerProfileRequest.new
        request.profile = CustomerProfileExType.new
        #Edit this part to select a specific customer
        request.profile.customerProfileId = customer_profile_id
        request.profile.merchantCustomerId = customer.id
        request.profile.description = customer.full_name
        request.profile.email = customer.try(:email)
        response = @transaction.update_customer_profile(request)
        if response.messages.resultCode == MessageTypeEnum::Ok
          Logs.update_transaction_log(customer, request.profile.customerProfileId, 'update customer profile', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Customer Profile')
          return request.profile.customerProfileId
        else
          Logs.update_transaction_log(customer, request.profile.customerProfileId, 'update customer profile', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Customer Profile')
          return nil
        end
      end

      def delete(customer, customer_profile_id)
        request = DeleteCustomerProfileRequest.new
        request.customerProfileId = customer_profile_id
        response = @transaction.delete_customer_profile(request)
        if response.messages.resultCode == MessageTypeEnum::Ok
          customer.update_column('authorizenet_profile_id', nil)
          Logs.update_transaction_log(customer, request.customerProfileId, 'delete customer profile', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Customer Profile')
          return request.customerProfileId
        else
          Logs.update_transaction_log(customer, request.customerProfileId, 'delete customer profile', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Customer Profile')
          return nil
        end
      end

    end
  end
end