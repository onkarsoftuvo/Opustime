# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:

# setting for cronjob on server by anuj
# loading rails environment
env :PATH, ENV['PATH']
env :GEM_PATH, ENV['GEM_PATH']
# set :environment, :development
set :environment, :production
set :output, '/opustime/shared/log/cron.log'


# this is for reminder setting implementation for all company account. by anuj from here

every 1.hour do
# every 1.minute do
  custom_cmd = 'cd /home/ubuntu/opustime/current/ && RAILS_ENV=production bundle exec rake opustime:reminder_notification '
  # rake 'opustime:reminder_notification'
  command custom_cmd
end


# Reminder for default sms for sms setting by anuj
every 1.day, at: '7:00 am' do
  rake 'reminder:account_default_sms'
end

# Trail subscription reminders for 3,2 and 1 days remaining
# 8 hours for production

# every 8.hours do
#   rake 'subscription:trial_expiry_reminder'
# end

# Auto Renew subscription reminders for 3,2 and 1 days remaining
# Auto Payment
# Auto update billing cycle or reset is_processed
# 12 hours for production
every 12.hours do
  rake 'subscription:auto_renew_reminder'
end

# check Quickbooks credentials for auto refresh
every 1.day, at: '6:00 pm' do
  rake 'intuit:auto_refresh_qbo_credentials'
end
