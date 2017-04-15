module PaymentGateway
  module NMI
    class CustomerVault < Service

      def initialize(customer_address)
        super()
        @shipping['firstname'] = customer_address.firstname
        @shipping['lastname'] = customer_address.lastname
        @shipping['company'] = customer_address.company
        @shipping['phone'] = customer_address.phone
        @shipping['address1'] = customer_address.address1
        @shipping['address2'] = customer_address.address2
        @shipping['city'] = customer_address.city
        @shipping['state'] = customer_address.state
        @shipping['zip'] = customer_address.zip
        @shipping['country'] = customer_address.country
        @shipping['email'] = customer_address.email
      end

      def create(company, credit_card, transaction_type)
        query = set_query_params(company, credit_card, transaction_type)
        return doPost(query)
      end

      def update(company, credit_card, transaction_type)
        query = set_query_params(company, credit_card, transaction_type)
        return doPost(query)
      end

      private

      def set_query_params(company, credit_card, transaction_type)
        query = ''
        # Login Information
        query = query + 'username=' + URI.escape(@login['username']) + '&'
        query += 'customer_vault_id=' + URI.escape(company.vault_id.to_s) + '&' if company.vault_id.present?
        query += 'password=' + URI.escape(@login['password']) + '&'
        query += 'ccnumber=' + URI.escape(credit_card.number.to_s) + '&'
        query += 'ccexp=' + URI.escape(credit_card.expiry_month.to_s+credit_card.expiry_year.to_s.slice!(2..3)) + '&'
        @shipping.each do |key, value|
          query += key +'=' + URI.escape(value) + '&' if value.present?
        end
        query += transaction_type
        return query
      end

    end
  end
end
