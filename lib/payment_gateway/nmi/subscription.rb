module PaymentGateway
  module NMI
    class Subscription < Service

      def initialize(company, plan=nil, next_billing_cycle=nil)
        super()
        # total no of recurring payments
        @plan_payments = 9999
        @plan = plan
        @company = company
        @plan_amount = plan.present? ? (plan.class.to_s.eql?('Plan') ? plan.price : plan.cost) : nil
        @month_frequency = plan.present? ? (plan.category.to_s.eql?('Yearly') ? 12 : 1) : nil
        @day_of_month = Time.now.day
        @start_date = if next_billing_cycle.present? then
                        next_billing_cycle.class.to_s.eql?('String') ? next_billing_cycle : next_billing_cycle.strftime('%Y%m%d').to_s
                      else
                        (Time.now+1.day).strftime('%Y%m%d').to_s
                      end
        @customer_vault_id = company.present? ? company.try(:vault_id) : nil
        @subscription_id = company.present? ? company.try(:subscription).try(:nmi_subscription_id) : nil
      end

      def create
        query = set_create_subscription_query_params('recurring=add_subscription')
        gateway_response = doPost(query)
        PaymentGateway::NMI::TransactionLog.new(gateway_response, @company).add_subscription_transaction_log(@plan_amount, @plan)
        return gateway_response
      end

      def cancel
        query = set_delete_subscription_query_params('recurring=delete_subscription')
        gateway_response = doPost(query)
        cost = @company.subscription.cost
        plan_id = @company.subscription.plan_id
        PaymentGateway::NMI::TransactionLog.new(gateway_response, @company).cancel_subscription_transaction_log(cost,plan_id)
        return gateway_response
      end

      # def update
      #   query = set_delete_subscription_query_params('recurring=update_subscription')
      #   return doPost(query)
      # end

      private

      def set_create_subscription_query_params(transaction_type)
        query = ''
        # Login Information
        query = query + 'username=' + URI.escape(@login['username']) + '&'
        query += 'password=' + URI.escape(@login['password']) + '&'
        query += 'customer_vault_id=' + URI.escape(@customer_vault_id) + '&'
        query += 'plan_payments=' + URI.escape(@plan_payments.to_s) + '&'
        query += 'plan_amount=' + URI.escape("%.2f" %@plan_amount) + '&'
        query += 'month_frequency=' + URI.escape(@month_frequency.to_s) + '&'
        query += 'day_of_month=' + URI.escape(@day_of_month.to_s) + '&'
        query += 'start_date=' + URI.escape(@start_date.to_s) + '&'
        query += transaction_type
        return query
      end

      def set_delete_subscription_query_params(transaction_type)
        query = ''
        # Login Information
        query = query + 'username=' + URI.escape(@login['username']) + '&'
        query += 'password=' + URI.escape(@login['password']) + '&'
        query += 'subscription_id=' + URI.escape(@subscription_id) + '&'
        query += transaction_type
        return query
      end

      # def set_update_subscription_query_params(transaction_type)
      #   query = ''
      #   # Login Information
      #   query = query + 'username=' + URI.escape(@login['username']) + '&'
      #   query += 'password=' + URI.escape(@login['password']) + '&'
      #   query += 'subscription_id=' + URI.escape(@subscription_id) + '&'
      #   query += 'start_date=' + URI.escape(@start_date) + '&'
      #   query += transaction_type
      #   return query
      # end

    end
  end
end