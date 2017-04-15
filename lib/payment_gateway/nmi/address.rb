module PaymentGateway
  module NMI
    class Address
      attr_accessor :firstname, :lastname, :company, :address1, :address2, :city, :state, :zip, :country, :phone, :fax, :email, :website

      def initialize(company=nil)
        @firstname = company.try(:first_name)
        @lastname = company.try(:last_name)
        @company = company.try(:company_name)
        @address1 = company.try(:address)
        @address2 = nil
        @city = company.try(:city)
        @state = company.try(:state)
        @zip = company.try(:postal_code)
        @country = company.try(:country)
        @phone = company.sms_number.number rescue nil
        @fax = nil
        @email = company.try(:email)
        @website = nil
      end

    end
  end
end