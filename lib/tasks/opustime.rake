namespace :subscription do
  require "#{Rails.root}/lib/opustime/utility.rb"
  include Opustime::Utility
  desc 'Update existing company trial plans'
  task :update_existing_company_trial_plan => :environment do
    Company.all.each { |company| company.subscription.update(:end_date => Date.today+30.days, :is_trial => true) }
  end

  desc 'Trail Checker to notify 7 days,3 days and 1 day remaining'
  task :trial_expiry_reminder => :environment do
    trail_companies = Company.joins(:subscription).where('subscriptions.is_trial=? and subscriptions.is_subscribed=?', true, false)
    if trail_companies.count > 0
      trail_companies.each do |company|

        subscription = company.subscription
        remaining_days = total_days(subscription.end_date, Date.today)
        reminders = subscription.reminders
        reminders_key = "trial_day_#{remaining_days}"

        if (!reminders[reminders_key] && [7, 3, 1].include?(remaining_days))
          TrailNotifyWorker.perform_async(company.id, remaining_days, reminders_key)
        elsif remaining_days <= 0
         ExpiryNotifyWorker.perform_async(company.id)
        end
      end
    end
  end


  desc 'Auto Renew Checker to notify 7 days,3 days remaining and auto payment'
  task :auto_renew_reminder => :environment do
    subscribed_companies = Company.joins(:subscription).where('subscriptions.is_subscribed=? and subscriptions.next_billing_cycle IS NOT NULL', true)
    subscribed_companies.each do |company|
      subscription = company.subscription
      remaining_days = total_days(subscription.next_billing_cycle.to_date, Date.today) rescue nil
      reminders = subscription.reminders
      reminders_key = "auto_renew_day_#{remaining_days}"

      if (!reminders[reminders_key] && [7, 3].include?(remaining_days) && (company.wallet > 0))
        p "=job_type='1_2_3_days_auto_renew_reminders'=company=#{company.id}==reminders_key=#{reminders_key}====reminders_status=#{reminders[reminders_key]}="
        TrailNotifyWorker.perform_async(company.id, remaining_days, reminders_key)
      elsif [2, 1].include?(remaining_days) && (company.wallet > 0) && (!subscription.is_processed)
        p "=job_type='auto_payment'=======company=#{company.id}==reminders_days=#{remaining_days}===="
        AutoPaymentWorker.perform_async(company.id, remaining_days)
      elsif [-2].include?(remaining_days)
        UpdateBillingCycle.perform_async(company.id, remaining_days)
      end
    end

  end

end


namespace :timeZone do
  task :save => :environment do
    ActiveSupport::TimeZone.all.each do |timeZone|
      country_name = timeZone.name
      tzinfo = timeZone.tzinfo
      offset = ActiveSupport::TimeZone[tzinfo.name].formatted_offset
      OpusTimezone.create(:city_name => country_name, :offset => offset, :timezone_name => tzinfo.name)
    end
  end

  task :save_formatted => :environment do
    grouped_time_zones = OpusTimezone.all.sort_by { |object| -object.offset.to_i }.group_by(&:timezone_name)
    # reset table
    OpusTimezone.destroy_all
    grouped_time_zones.each do |timeZone, details|
      all_cities = []
      details.each { |detail| all_cities.push(detail.city_name) }
      offset = details.first.offset
      OpusTimezone.create(:all_cities => all_cities, :offset => offset, :timezone_name => timeZone)
    end
  end

end

