RailsExceptionHandler.configure do |config|
  config.environments = [:production] # Defaults to [:production]
  # config.fallback_layout = 'home'                                         # Defaults to 'application'
  # config.after_initialize do
  #   # This block will be called after the initialization is done.
  #   # Usefull for interaction with authentication mechanisms, which should
  #   # only happen when the exception handler is enabled.
  # end
  # config.filters = [                                                      # No filters are  enabled by default
  #   :all_404s,
  #   :no_referer_404s,
  #   :anon_404s,
  #   {:user_agent_regxp => /\b(ApptusBot|TurnitinBot|DotBot|SiteBot)\b/i},
  #   {:target_url_regxp => /\.php/i},
  #   {:referer_url_regxp => /problematicreferer/i}
  # ]
  #
  # !!! IMPORTANT !!!
  # You must remove public/500.html and public/404.html for these to have any effect
  config.responses = {
      :default => "<h1>500</h1><p>Internal server error</p>",
      :not_found => "<h1>404</h1><p>Page not found</p>"
  }

  # All errors are mapped to the :default response unless overridden here
  config.response_mapping = {
      'ActiveRecord::RecordNotFound' => :not_found,
      'ActionController::RoutingError' => :not_found,
      'AbstractController::ActionNotFound' => :not_found,
      'ActionController::InvalidAuthenticityToken' => :wrong_token,
      'ActiveRecord::Rollback' => :rollback,
      'ActiveRecord::RecordInvalid' => :invalid,
      'ActiveRecord::PendingMigrationError' => :pending_migration,
      'Teapot::CoffeeGroundsNotSupported' => :teapot
  }

  config.storage_strategies = [:active_record] # Available options: [:active_record, :rails_log, :remote_url => {:target => 'http://example.com'}]
  # Change database/table for the active_record storage strategy
  config.active_record_store_in = {
      :database => Rails.env.production? ? 'production' : 'development',
      :record_table => 'opustime_logs'
  }


  config.store_request_info do |storage, request|
    storage[:target_url] = request.url
    storage[:referer_url] = request.referer
    storage[:params] = request.params.inspect
    storage[:user_agent] = request.user_agent
  end

  config.store_exception_info do |storage, exception|
    storage[:class_name] = exception.class.to_s
    storage[:message] = exception.to_s
    storage[:trace] = exception.backtrace.join("\n")
  end

  config.store_environment_info do |storage, env|
    storage[:gateway_interface] = env["GATEWAY_INTERFACE"]
    # storage[:doc_root] =     Rails.root
  end

  config.store_global_info do |storage|
    storage[:app_name] = Rails.application.class.parent_name
    storage[:created_at] = Time.zone.now
  end
  config.store_user_info = {:method => :current_user, :field => :combine_ids} # Helper method for easier access to current_user
end
