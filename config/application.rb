require File.expand_path('../boot', __FILE__)

require 'csv'
require 'rails/all'
require 'curb'
require 'net/http'
require 'open-uri'
require 'json'
require 'nokogiri'
require 'uri'
require 'addressable/uri'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

CONFIG = YAML.load(File.read(File.expand_path('../appconfig.yml', __FILE__)))
CONFIG.merge! CONFIG.fetch(Rails.env, {})
CONFIG.symbolize_keys!

module Enake
  class Application < Rails::Application
    config.assets.precompile << 'delayed/web/application.css'
    config.assets.enabled = true
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.autoload_paths += %W( #{config.root}/lib )
    # config.cache_store = :redis_store, 'redis://localhost:6379', { expires_in: 90.minutes }

    # Do not swallow errors in after_commit/after_rollback callbacks.
    # config.web_console.whitelisted_ips = '112.196.33.87'

    config.action_mailer.default_url_options = {host: 'http://54.173.17.29/'}
    config.active_record.raise_in_transactional_callbacks = true
    config.active_record.whitelist_attributes = true

    #     for heroku deploy with precompile assets
    config.assets.initialize_on_precompile=false
    config.active_record.default_timezone = :local
    # config.web_console.automount = true
    config.active_record.observers = :company_observer
    config.active_job.queue_adapter = :sidekiq,:delayed_job
    config.force_ssl = false

    # set the default locale to English
    config.i18n.default_locale = :en
    # if a locale isn't found fall back to this default locale
    config.i18n.fallbacks = true
    # set the possible locales to English and Brazilian-Portuguese
    # config.i18n.available_locales = [:en, :'fr']

    config.action_mailer.delivery_method = :smtp
    # config.action_mailer.smtp_settings = {
    #   address:              'smtp.gmail.com',
    #   port:                 587,
    #   domain:               'gmail.com',
    #   user_name:            'zulutesting7',
    #   password:             'zulu260!',
    #   authentication:       'plain',
    #   enable_starttls_auto: true
    # }

    Koala.config.api_version = 'v2.0'
  end
end
