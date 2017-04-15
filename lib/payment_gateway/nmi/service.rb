module PaymentGateway
  module NMI
    class Service
      def initialize
        @login = {}
        @billing = {}
        @shipping = {}
        @login['username'] = NMI_CONFIG['username']
        @login['password'] = NMI_CONFIG['password']
        # configure NMI Direct Post connection
        NmiDirectPost::Base.establish_connection(NMI_CONFIG['username'],  NMI_CONFIG['password'])
      end


      # Generic method for NMI direct posting
      def doPost(query)
        curlObj = Curl::Easy.new('https://secure.networkmerchants.com/api/transact.php')
        curlObj.connect_timeout = 30
        curlObj.timeout = 30
        curlObj.header_in_body = false
        curlObj.ssl_verify_peer = true
        curlObj.post_body = query
        curlObj.perform()
        data = curlObj.body_str
        data = 'https://secure.networkmerchants.com/api/transact.php?' + data
        uri = Addressable::URI.parse(data)
        @responses = uri.query_values
        return @responses
      end

    end

  end
end