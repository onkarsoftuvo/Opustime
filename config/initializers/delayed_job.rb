require 'delayed_job'
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 30
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 30.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Rails.env.test? ? Logger.new(File.join('/home/ubuntu/opustime/shared', 'log', 'delayed_job.log')) : Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

Delayed::Web::Engine.middleware.use Rack::Auth::Basic do |username, password|
  [username, password] == %w(delayed_job slinfy_123)
end
