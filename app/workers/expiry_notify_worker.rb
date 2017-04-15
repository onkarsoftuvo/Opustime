class ExpiryNotifyWorker
  include Sidekiq::Worker
  include Sidekiq::Lock::Worker
  # static lock that expires after one second
  sidekiq_options lock: {timeout: 1000*30, name: 'expiry_notify_lock_worker'}
  # default locking time 30 seconds
  sidekiq_options unique: :until_and_while_executing, :queue => 'subscription'

  def perform(company_id)

    if lock.acquire!
      begin
        target = open("#{LOG_PATH}/log/cron.log", 'a')
        target.write("---job=1---job_name='trial_expiry'----- start_time=#{DateTime.now}----------")
        target.write("---job=1---is executing for company_id=#{company_id}-----------")
        company = Company.find_by_id(company_id)
        # expire trial
        company.subscription.update_columns(:is_trial => false, :is_subscribed => false)
        target.write("-job=1-company_id=#{company_id}--trail subscription is expired---\n") if !company.subscription.is_trial
        # send reminder email
        target.close
        SubscriptionMailer.expire_trial_subscription(company).deliver
        target.write("---job=1---job_name='trial_expiry'----- end_time=#{DateTime.now}----------")
        target.close
      ensure
        lock.release!
      end
    else
      # reschedule, raise an error or do whatever you want
    end

  end
end