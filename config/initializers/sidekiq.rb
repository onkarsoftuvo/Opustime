require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq/middleware/i18n'

REDIS_HOST = '127.0.0.1'
REDIS_PORT = '6379'

Sidekiq.hook_rails!
Sidekiq.remove_delay!


Sidekiq.configure_server do |config|
  config.redis = {:url => "redis://#{REDIS_HOST}:#{REDIS_PORT}/12", :namespace => 'Sidekiq'}
end

Sidekiq.configure_client do |config|
  config.redis = {:url => "redis://#{REDIS_HOST}:#{REDIS_PORT}/12", :namespace => 'Sidekiq'}
end


Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == %w(sidekiq slinfy_123)
end

