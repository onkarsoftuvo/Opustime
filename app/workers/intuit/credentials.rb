module Intuit
  class Credentials

    def initialize(token, secret, realm_id)
      # set QBO Credentials
      @token = token
      @secret = secret
      @realm_id = realm_id
    end
  end
end