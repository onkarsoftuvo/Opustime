module PaymentGateway
  module Authorizenet
    class Subscription < Authorizenet::Connection

      include AuthorizeNet::API

      def create(customer, customer_profile_id, customer_payment_profile_id)

        request = ARBCreateSubscriptionRequest.new
        request.refId = customer.id
        request.subscription = ARBSubscriptionType.new
        request.subscription.name = customer.full_name
        request.subscription.paymentSchedule = PaymentScheduleType.new

        if @category.to_s.downcase.eql?('monthly')
          request.subscription.paymentSchedule.interval = PaymentScheduleType::Interval.new('1', 'months')
        else
          request.subscription.paymentSchedule.interval = PaymentScheduleType::Interval.new('12', 'months')
        end

        request.subscription.paymentSchedule.startDate = (DateTime.now).to_s[0...10]
        request.subscription.paymentSchedule.totalOccurrences ='9999'
        # request.subscription.paymentSchedule.trialOccurrences ='1'
        request.subscription.amount = @price
        # request.subscription.trialAmount = 0.00

        request.subscription.profile = CustomerProfileIdType.new
        request.subscription.profile.customerProfileId = customer_profile_id
        request.subscription.profile.customerPaymentProfileId = customer_payment_profile_id

        response = @transaction.create_subscription(request)

        if response.messages.resultCode == MessageTypeEnum::Ok
          Logs.update_transaction_log(customer, response.subscriptionId, 'create customer subscription', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Subscription Payment', @price)
          return response.subscriptionId, response.messages.messages[0].text
        else
          Logs.update_transaction_log(customer, response.subscriptionId, 'create customer subscription', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Subscription Payment', @price)
          return nil, response.messages.messages[0].text
        end

      end

      def update(customer, subscription_id, customer_profile_id, customer_payment_profile_id)
        request = ARBUpdateSubscriptionRequest.new
        request.refId = customer.id
        request.subscriptionId = subscription_id
        request.subscription = ARBSubscriptionType.new

        request.subscription.profile = CustomerProfileIdType.new
        request.subscription.profile.customerProfileId = customer_profile_id
        request.subscription.profile.customerPaymentProfileId = customer_payment_profile_id
        response = @transaction.update_subscription(request)

        if response.messages.resultCode == MessageTypeEnum::Ok
          Logs.update_transaction_log(customer, subscription_id, 'update customer subscription', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Subscription Payment', @price)
          return subscription_id
        else
          Logs.update_transaction_log(customer, subscription_id, 'update customer subscription', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Subscription Payment', @price)
          return nil
        end
      end

      def cancel(customer, subscription_id)

        request = ARBCancelSubscriptionRequest.new
        request.refId = customer.id
        request.subscriptionId = subscription_id

        response = @transaction.cancel_subscription(request)

        if response.messages.resultCode == MessageTypeEnum::Ok
          Logs.update_transaction_log(customer, subscription_id, 'delete customer subscription', response.messages.messages[0].code, response.messages.messages[0].text, false, 'Subscription Payment', @price)
          return subscription_id, response.messages.messages[0].text
        else
          Logs.update_transaction_log(customer, subscription_id, 'delete customer subscription', response.messages.messages[0].code, response.messages.messages[0].text, true, 'Subscription Payment', @price)
          return nil, response.messages.messages[0].text
        end

      end

    end
  end
end