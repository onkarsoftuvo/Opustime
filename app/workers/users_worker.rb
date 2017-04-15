class UsersWorker 
  include Sidekiq::Worker
  sidekiq_options retry: true
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*15, name: 'default_sms_worker'}
  
  def perform(user_id , temp_password)
    if lock.acquire!
      begin
        user = User.find_by_id(user_id)
        UserMailer.welcome_email(user , temp_password ).deliver_now
      ensure
        lock.release!
      end
    end
  end
  
end