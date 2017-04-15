class DefaultSmsReminder
  include Sidekiq::Worker
  include PlivoSms
  include Reminder::ReadyMade
  sidekiq_options retry: false
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*25, name: 'default_sms_worker'}

  def perform
    if lock.acquire!
      begin
        subscribed_accounts = Company.joins(:subscription).where(["subscriptions.is_subscribed = ?" , true])
        subscribed_accounts.each do |company|
          sms_reminder_default_sms(company)
        end
      ensure
        lock.release!
      end
    end
  end
end