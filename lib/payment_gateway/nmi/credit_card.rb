require 'active_merchant/billing/rails'
module PaymentGateway
  module NMI
    class CreditCard

      attr_accessor :company, :number, :expiry_month, :expiry_year, :cvv

      def initialize(credit_card={}, company=nil)
        @first_name = company.try(:first_name)
        @last_name = company.try(:last_name)
        @number = credit_card[:card_number]
        @expiry_month = credit_card[:expiry_month]
        @expiry_year = credit_card[:expiry_year]
        @cvv = credit_card[:cvv]
      end

      def validate
        credit_card = ActiveMerchant::Billing::CreditCard.new(
            :first_name => @first_name,
            :last_name => @last_name,
            :number => @number,
            :month => @expiry_month,
            :year => @expiry_year,
            :verification_value => @cvv
        )

        credit_card.valid? ? (return true, nil) : (return false, build_card_error(credit_card.validate))
      end

      def build_card_error(error_arr)
        error_msg = []
        error_arr.keys.each do |key|
          item= {}
          if key.to_s.eql?('number')
            item[:error_name] = 'card number'
          elsif key.to_s.eql?('verification_value')
            item[:error_name] = 'cvv'
          else
            item[:error_name] = key.to_s.split(' ').join(' ')
          end
          item[:error_msg] = error_arr[key].first
          error_msg << item
        end
        return error_msg
      end

    end
  end
end