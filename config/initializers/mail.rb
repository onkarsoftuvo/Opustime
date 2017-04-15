ActionMailer::Base.register_interceptor(SendGrid::MailInterceptor)

ActionMailer::Base.smtp_settings = {
  :user_name =>  CONFIG[:send_grid_user_name],
  :password =>  CONFIG[:send_grid_password],
  :domain => 'app.opustime.com',
  :address => 'smtp.sendgrid.net',
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true
}

SendGrid.configure do |config|
  config.dummy_recipient = 'no_reply@opustime.com'
end
