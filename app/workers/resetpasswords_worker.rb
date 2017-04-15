class ResetpasswordsWorker
  include Sidekiq::Worker
  sidekiq_options retry: true
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*3, name: 'reset_worker'}
  
  def perform(user_id)
    if lock.acquire!
      begin
        user = User.find_by_id(user_id)
        UserMailer.password_reset(user).deliver_now
      ensure
        lock.release!
      end
    end
  end
end