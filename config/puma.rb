# Change to match your CPU core count
workers 4

# Min and Max threads per worker
threads 0, 4
preload_app!

# Default to production
#rails_env = ENV['RAILS_ENV'] || 'development'
rails_env = ENV['RAILS_ENV'] || 'production'
environment rails_env

shared_path = ENV['RAILS_ENV'].to_s.eql?('production') ? '/home/ubuntu/opustime/shared' : './config/shared'

daemonize true if ENV['RAILS_ENV'].to_s.eql?('production')

# # Set up socket location
if ENV['RAILS_ENV'].to_s.eql?('production')
  bind "unix://#{shared_path}/sockets/puma.sock"
else
  bind 'tcp://127.0.0.1:3000'
end

# Logging
stdout_redirect "#{shared_path}/log/puma.stdout.log", "#{shared_path}/log/puma.stderr.log", true

# Set master PID and state locations
pidfile "#{shared_path}/pids/puma.pid"
state_path "#{shared_path}/pids/puma.state"

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect!
  # Puma Worker Killer configuration block
  PumaWorkerKiller.config do |config|
    config.ram = 6144 # mb
    config.frequency = 60 # seconds
    config.percent_usage = 0.98
    config.rolling_restart_frequency = 6 * 3600 # 6 hours in seconds
  end
  PumaWorkerKiller.start
end
