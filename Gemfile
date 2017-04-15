source 'http://rubygems.org'

ruby '2.2.2'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.3'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'less-rails-bootstrap'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'
gem 'responders', '~> 2.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
gem 'bcrypt'

gem 'protected_attributes'
gem 'time_diff'
gem 'actionview'
gem 'cancancan', '~> 1.10'
gem 'rubyzip', '~> 1.2'
gem 'zip-zip'
gem 'roo'

gem 'sidekiq'
gem 'sinatra', require: false
gem 'slim'
gem 'redis-namespace'
gem 'mina-sidekiq', :require => false
gem 'mina-faye',:require => false
gem 'mina-nginx', :require => false
# lock sidekiq shared resource
# gem 'sidekiq-lock'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-failures'
gem 'sidekiq-client-cli'
gem 'sidekiq-scheduler'
gem 'sendgrid-rails', '~> 2.0'
gem 'activemerchant', '~> 1.60'

# Use puma as the app server
gem 'puma', '~> 3.6', '>= 3.6.2'
gem 'puma_worker_killer'
gem 'mina'
# gem 'mina-unicorn', :require => false
# gem 'mina-puma', :require => false
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# gem 'xero_gateway'
# for QBO integration and API
gem 'quickbooks-ruby', '~> 0.4.6'
gem 'qbo_api', '~> 1.4', '>= 1.4.1'
gem 'oauth-plugin', '~> 0.5.1'
# for serialize/deserialize objects
gem 'redis'
gem 'sidekiq-lock'

# for Authorize.net payment gateway
gem 'authorizenet', '~> 1.8.9.1'
gem 'active_model_serializers', '~> 0.10.0' #  replace all api json format with Serializer  see business model

gem 'angularjs-rails'
gem 'angular_rails_csrf'
gem 'rspec-rails' # for unit testing code
gem 'rails-observers' # Observer has been removed out of rails 4 . It's a way to add it in rails 4
gem 'paperclip', :git=> 'https://github.com/thoughtbot/paperclip', :ref => '523bd46c768226893f23889079a7aa9c73b57d68'
# gem 'aws-sdk', '~> 1.50.0'
gem 'aws-sdk', '>= 2.0.34'
gem 'mysql2', '~> 0.3.20'

# gems for integrations
gem 'mailchimp-api', require: 'mailchimp'

#gem for admin adding by manoranjan
gem 'jquery-datatables-rails'
gem 'ajax-datatables-rails'
gem 'bootstrap-sass'
gem 'adminlte-rails'
#gem 'jquery-datatables-rails', '~> 3.2'
gem 'icheck-rails'
gem 'momentjs-rails'
gem 'chartjs-ror'
#gem 'ckeditor'
gem 'city-state'
gem 'breadcrumbs_on_rails'
gem 'countries', :require => 'countries/global'
gem 'phony'
gem 'audited-activerecord'
gem 'public_activity'
gem 'jquery-turbolinks'

gem 'wicked_pdf'
gem 'wkhtmltopdf-binary-edge', '~> 0.12.2.1'

gem 'will_paginate', '~> 3.1'

gem 'validates_zipcode'

# Gem for cron job processes
 gem 'whenever', :require => false
# gem 'whenever-elasticbeanstalk'

# gem 'google-api-client', :require => 'google/apis'
gem 'google-api-client', '<0.9' ,  :require => 'google/api_client'
gem 'omniauth' , '~> 1.2.2'
gem 'omniauth-google-oauth2'
gem 'omniauth-facebook'
gem 'chronic', '~> 0.10.2'

gem 'icalendar', '~> 2.3'

#gem added by manoranjan
gem 'koala', '~> 2.2'
gem 'plivo', '~> 0.3.19'
gem 'rest-client', '~> 1.6.7'
gem 'nokogiri'
# gem "rails-erd"    # to generate erb diagram of models

# for appointment recurring events


# both gems are using for assets availability of angularjs on production env
# gem 'angular-rails-templates'
# gem 'bower-rails'

# session store in db
gem 'activerecord-session_store'


group :development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'rake', '~> 11.2.0'
  gem 'better_errors'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # gem "awesome_print", require:"ap"
  # for starting all process
  gem 'foreman'
  # Use mysql2 as the database for Active Record
  gem 'web-console'

end

group :production do

  gem 'sprockets-rails', '~> 3.2', :require => 'sprockets/railtie'
  gem 'sprockets', '3.6.3'
end

# for application error handling and logging
gem 'rails_exception_handler', '~> 2'

# gem 'google-authenticator-rails'
gem 'active_model_otp'
gem 'rqrcode'

# curl API hitting
gem 'curb'
# for handling web push notifications
gem 'faye'
gem 'thin'
# phone number global Normalization
gem 'phony_rails'
# NMI direct post api
gem 'nmi_direct_post'

# pingdom system tracking
gem 'thor'
gem 'soap4r'

#invoice number generator
gem 'invoice_number'
# ip to timezone geo-coding
gem 'geocoder'
# for form submit via ajax
gem 'remotipart', '~> 1.2'
# command gem
gem 'command', '~> 1.0'
#Authentication Solution
gem 'devise'
# currency conversion
gem 'money'
# Delayed job for Quickbooks posting
gem 'delayed_job_active_record', '~> 4.1', '>= 4.1.1'
# for mina deployment
gem 'mina-delayed_job', require: false
gem 'daemons'
gem 'delayed-web'
gem 'bootstrap-switch-rails'
