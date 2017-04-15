namespace :reminder do
  task :account_default_sms => :environment do
    DefaultSmsReminder.perform_async
  end
end

namespace :opustime do
  task :reminder_notification => :environment do
    ReminderWorker.perform_async
  end
end

namespace :opustime do
  task :format_contact_numbers => :environment do
    FormatContactnoWorker.perform_async
  end
end