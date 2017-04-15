module Quickbooks
  class Connection

    # Initialize QBO JASON API Connection
    def initialize(token, secret, company_id, company=nil)
      # for qbo_api gem usage
      @token = token
      @secret = secret
      @realm_id = company_id
      @company = company
      @qbo_api = QboApi.new(token: token, token_secret: secret, realm_id: company_id, consumer_key: $qb_key, consumer_secret: $qb_secret)
      # for quickbooks ruby gem usage
      @access_token = OAuth::AccessToken.new($qb_oauth_consumer, token, secret)
      # initialize item service
      @item_service = Quickbooks::Service::Item.new(:company_id => company_id, :access_token => @access_token)
      # initialize customer service
      @customer_service = Quickbooks::Service::Customer.new(:company_id => company_id, :access_token => @access_token)
      # initialize invoice service
      @invoice_service = Quickbooks::Service::Invoice.new(:company_id => company_id, :access_token => @access_token)
    end

    # reconnect Quickbooks
    def reconnect

    end

    # disconnect Quickbooks
    def disconnect(company)
      begin
        response = @qbo_api.disconnect
        if response['ErrorCode'].to_i == 0
          # destroy all Quickbooks company taxes and accounts
          logs = Quickbooks::Logs.new(company)
          company.tax_settings.where(:qbo_tax => true).destroy_all
          company.qbo_accounts.destroy_all
          logs.update_success_log('Quickbooks Successfully Disconnected', 'disconnect', false, logs)
        end
      rescue QboApi::BadRequest, Exception => e
        logs.update_error_log(e.message, 'disconnect', true, logs)
      end
    end

    # catch qbo exception while executing api
    def record_exception_while_executing_qbo_api(company, object)
      logs = Quickbooks::Logs.new(company)
      logs.update_error_log(object, "error while processing #{object.class} of id #{object.id}", 'exception', true, logs)
    end
  end


end