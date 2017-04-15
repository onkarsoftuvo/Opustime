module Quickbooks
  class Logs < Quickbooks::ShareCompanyDetail

    # update success logs into db
    def update_success_log(loggable=nil, info, action_name, error_status, logs)
      logs.commit_into_db(loggable, info, action_name, error_status, logs)
      p 'No Error while posting data to QBO...!'
    end

    # update error logs into db
    def update_error_log(loggable=nil, error, action_name, error_status, logs)
      logs.commit_into_db(loggable, error, action_name, error_status, logs)
      p 'Error while posting data to QBO...!'
    end

    # final commit into db
    def commit_into_db(loggable, error, action_name, error_status, logs)
      QboLog.transaction do
        quick_books_logs = logs.company.qbo_logs.build(:loggable => loggable, :action_name => "#{action_name}", :message => "#{error}", :status => error_status)
        quick_books_logs.with_lock { quick_books_logs.save }
      end

    end
  end
end