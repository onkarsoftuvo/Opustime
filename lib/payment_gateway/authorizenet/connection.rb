module PaymentGateway
  module Authorizenet
    class Connection
      include AuthorizeNet::API
      # Initialize Authorize.net transaction object
      def initialize(price=nil, category=nil)
        # payment price and subscription category
        @price = price
        @category = category
        @transaction = Transaction.new(AUTHORIZENET_CONFIG['api_login_key'], AUTHORIZENET_CONFIG['api_transaction_key'], :gateway => :sandbox)
      end

    end
  end
end
