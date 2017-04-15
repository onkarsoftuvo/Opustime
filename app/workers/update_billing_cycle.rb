class UpdateBillingCycle
  include Sidekiq::Worker
  sidekiq_options retry: true
  include Sidekiq::Lock::Worker
  sidekiq_options lock: {timeout: 1000*15, name: 'update_billing_cycle_lock'}

  def perform(company_id, remaining_days)
    if lock.acquire!
      begin
        target = open("#{LOG_PATH}/log/cron.log", 'a')
        target.write("===job=4===job_name='update_billing_cycle_or_reset_is_processed'===start_time=#{Time.now}====remaining_days=#{remaining_days}===\n")
        target.write("---job=4 executing for company_id=#{company_id}-and remaining_days=#{remaining_days}---------\n")
        company = Company.find_by_id(company_id)
        subscription = company.subscription
        next_billing_cycle = subscription.category.to_s.eql?('Yearly') ? (Time.now+1.year+remaining_days.day) : (Time.now+1.month+remaining_days.day)
        subscription.is_processed ? subscription.update_column(:is_processed, false) : subscription.update_column(:next_billing_cycle, next_billing_cycle)
        target.write("===job=4===job_name='update_billing_cycle_or_reset_is_processed'===end_time=#{Time.now}=====\n")
        target.close
      ensure
        lock.release!
      end
    end
  end

end