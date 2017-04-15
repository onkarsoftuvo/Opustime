Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # config.log_level = :info
  # config.lograge.enabled = true
  # config.lograge.formatter = Lograge::Formatters::Logstash.new
  # config.logger = LogStashLogger.new(type: :tcp, host: '127.0.0.1', port: 5043)

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Load Quickbooks Credentials
  QBO_CONFIG = YAML.load_file(Rails.root.join('config/quickbooks.yml'))[Rails.env]

  # Load NMI Credentials
  NMI_CONFIG = YAML.load_file(Rails.root.join('config/nmi.yml'))[Rails.env]

  # Load Redis Credential
  REDIS_CONFIG = YAML.load_file(Rails.root.join('config/redis.yml'))[Rails.env]

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  # config.action_dispatch.tld_length = 0

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.serve_static_files =  true

  config.active_support.deprecation = :log

  config.assets.paths << File.join(Rails.root, 'app', 'assets', 'online_booking')
  config.assets.paths << File.join(Rails.root, 'app', 'assets', 'angular')
  config.assets.paths << File.join(Rails.root, 'app', 'assets', 'libs')
  config.assets.paths << File.join(Rails.root, 'app', 'assets', 'stylesheets', 'fonts')
  config.assets.paths << File.join(Rails.root, 'app', 'assets', 'stylesheets', 'main_app')
  config.assets.paths << File.join(Rails.root, 'app', 'assets', 'stylesheets', 'online_booking')
  config.assets.paths << File.join(Rails.root, 'app', 'assets', 'stylesheets', 'admin_dashboard')

  # config.assets.paths << File.join(Rails.root, 'app', 'assets', 'stylesheets', 'fonts')

  # Compress JavaScripts and CSS.



  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true
  config.assets.js_compressor = :uglifier

  %w{javascripts/angular/*.js javascripts/admin_dashboard/* javascripts/online_booking/*.js javascripts/libs/*.js stylesheets/*.css  stylesheets/fonts/* stylesheets/main_app/* stylesheets/online_booking/*}.each do |dir|
    config.assets.paths << Rails.root.join("app/assets/#{dir}").to_s
  end

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  #config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug
  config.autoflush_log = true

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  # config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  Paperclip.options[:command_path] = "/usr/bin/"

  # config.serve_static_assets = true

  #    mailer setting adding by Anuj

  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_options = {from: 'no-reply@opustime.com'}
  config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'ALLOWALL'
  }

  #   ending here


  config.action_dispatch.x_sendfile_header = nil

  config.assets.js_compressor = Uglifier.new(mangle: false)
  PUBLIC_URL = "https://app.opustime.com/"

  # Amazon Web Services - S3
  config.paperclip_defaults = {
      :storage => :s3,
      :s3_signature_version  => :v4,
      :s3_region => 'ca-central-1',
      :s3_host_name => 's3.ca-central-1.amazonaws.com',
      :s3_credentials => {
          :bucket => 'productionserverbucket',
          :access_key_id => 'AKIAJYZHW26BKHAVEN6A',
          :secret_access_key => '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',
          :set_public =>  true
      }
  }

end
