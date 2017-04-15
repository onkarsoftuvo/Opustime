module Authentication
  extend ActiveSupport::Concern
  
  included do
    has_secure_password
  end
  
  module ClassMethods
    def authenticate_by_email(email, password)     # only for user model using
      user = find_by_email(email)
      if user && user.authenticate(password)
        user
      else
        nil
      end
    end
  end
end
