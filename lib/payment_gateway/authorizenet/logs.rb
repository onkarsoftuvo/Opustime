module PaymentGateway
  module Authorizenet
    class Logs

      # update success logs into db
      def self.update_transaction_log(company, response_id, action_name, response_code, response_message, error_status, transaction_type, amount=nil)
        Logs.commit_into_db(company, response_id, action_name, response_code, response_message, error_status, transaction_type, amount)
      end

      # final commit into db
      def self.commit_into_db(company, response_id, action_name, response_code, response_message, error_status, transaction_type, amount)
        company.transaction_logs.create(:response_id => response_id, :response_code => response_code, :response_message => response_message, :action_name => "#{action_name}", :error_status => error_status, :transaction_type => transaction_type, :amount => amount)
      end
    end
  end
end