class TrailNotifyWorker
  include Sidekiq::Worker
  include Sidekiq::Lock::Worker
  include Opustime::Utility

  # static lock that expires after one second
  sidekiq_options lock: {timeout: 1000*30, name: 'trail_or_renew_notify_lock_worker'}
  # default locking time 30 seconds
  sidekiq_options unique: :until_and_while_executing, :queue => 'subscription'

  def perform(company_id, no_of_days, reminders_key)

    if lock.acquire!
      begin
        target = open("#{LOG_PATH}/log/cron.log", 'a')
        target.write("---job=2---job_name='auto_renew_reminder_email'----- start_time=#{DateTime.now}----------")
        target.write("---job=2 executing for company_id#{company_id}-and no_of_days=#{no_of_days}---------")
        company = Company.find_by_id(company_id)
        subscription = company.subscription
        reminders = subscription.reminders
        # send reminder email
        SubscriptionMailer.days_left_subscription_expiry(company, no_of_days).deliver
        subscription.update_columns(:reminders => modify_hash_by_key(reminders, reminders_key))
        target.write("---job=2---job_name='auto_renew_reminder_email'-----end_time=#{DateTime.now}----------")
      ensure
        lock.release!
      end
    else
      # reschedule, raise an error or do whatever you want
    end

  end
end