class AutoPaymentWorker
  include Sidekiq::Worker
  include Sidekiq::Lock::Worker
  include SubscriptionHelper
  include Opustime::Utility
  # static lock that expires after one second
  sidekiq_options lock: {timeout: 1000*30, name: 'auto_payment_lock_worker'}
  # default locking time 30 seconds
  sidekiq_options unique: :until_and_while_executing, :queue => 'subscription'

  def perform(company_id, remaining_days)
    if lock.acquire!
      begin
        company = Company.find_by_id(company_id)
        # get current subscription
        subscription = company.subscription
        # get wallet amount
        wallet_amount = company.wallet
        next_billing_cycle = subscription.category.to_s.eql?('Yearly') ? (Time.now+1.year+remaining_days.day).strftime('%Y%m%d').to_s : (Time.now+1.month+remaining_days.day).strftime('%Y%m%d').to_s
        current_billing_cycle = subscription.next_billing_cycle

        if wallet_amount >= subscription.cost
          target = open("#{LOG_PATH}/log/cron.log", 'a')
          target.write("===job=3===job_name='auto_subscription_payment'===start_time=#{Time.now}=====\n")
          target.write("==process_start_time=#{Time.now}====for_case_1=====for_company=#{company.id}============\n")
          # make full payment to use wallet amount
          available_wallet_amount = wallet_amount - subscription.cost.to_f
          # cancel and renew subscription
          gateway_response = cancel_and_renew_subscription(company, subscription.plan, next_billing_cycle)
          target.write("========job=3======subscription_response====for_case_1==#{gateway_response}======for_company=#{company.id}====wallet=#{wallet_amount}==plan_amount=#{subscription.cost}==========\n")

          if gateway_response['response'].to_s.eql?('1')
            # payment_type=> 0 (partial wallet payment)
            # payment_type=>1 (full wallet payment)
            subscription.payment_type = 1
            payment_info = {:used_wallet_amount => subscription.cost, :wallet_credit => 0, :payable_amount => 0, :last_plan => company.subscription.cost}
            # update wallet balance
            company.update_columns(:wallet => available_wallet_amount)
            subscription.update_columns(:is_processed => true, :current_billing_cycle => current_billing_cycle, :next_billing_cycle => next_billing_cycle, :payment_info => payment_info, :nmi_subscription_id => gateway_response['subscription_id'])
          end
          target.write("==process_end_time=#{Time.now}====for_case_1=====for_company=#{company.id}============\n")
          target.write("===job=3===job_name='auto_subscription_payment'===end_time=#{Time.now}=====\n")
          target.close
        else
          target = open("#{LOG_PATH}/log/cron.log", 'a')
          target.write("===job=3===job_name='auto_subscription_payment'===start_time=#{Time.now}=====\n")
          # make payment by card and wallet
          target.write("==process_start_time=#{Time.now}====for_case_2=====for_company=#{company.id}============\n")
          payable_amount = subscription.cost - wallet_amount
          gateway_response = credit_card_payment(company, payable_amount, subscription.plan)
          # gateway_response = {}
          # gateway_response['response'] = '1'
          target.write("========job=3======payment_response=#{gateway_response}======for_company=#{company.id}====payable=#{payable_amount}=wallet=#{wallet_amount}==plan_amount=#{subscription.cost}==========\n")
          # cancel and renew subscription
          gateway_response = cancel_and_renew_subscription(company, subscription.plan, next_billing_cycle) if gateway_response['response'].to_s.eql?('1')
          target.write("============job=3===subscription_gateway_response=#{gateway_response}======for_company=#{company.id}=================\n")
          # reset wallet balance
          if gateway_response['response'].to_s.eql?('1')
            # payment_type=> 0 (partial wallet payment)
            # payment_type=>1 (full wallet payment)
            subscription.payment_type = 0
            payment_info = {:used_wallet_amount => wallet_amount, :wallet_credit => 0, :payable_amount => payable_amount, :last_plan => company.subscription.cost}
            company.update_columns(:wallet => 0)
            subscription.update_columns(:is_processed => true, :current_billing_cycle => current_billing_cycle, :next_billing_cycle => next_billing_cycle, :payment_info => payment_info, :nmi_subscription_id => gateway_response['subscription_id'])
          end
          target.write("==process_end_time=#{Time.now}====for_case_2=====for_company=#{company.id}============\n")
          target.write("===job=3===job_name='auto_subscription_payment'===end_time=#{Time.now}=====\n")
          target.close
        end
      ensure
        lock.release!
      end
    else
      # reschedule, raise an error or do whatever you want
    end

  end


end