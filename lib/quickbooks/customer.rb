module Quickbooks
  class Customer < Quickbooks::Connection

    # Set QBO customer model attributes
    def set_qbo_attributes_hash(customer)
      {
          :BillAddr => {
              :Line1 => "#{customer.address}",
              :City => "#{customer.city}",
              :Country => "#{customer.country}",
              :PostalCode => "#{customer.postal_code}"
          },
          :Title => "#{customer.title}",
          :GivenName => "#{customer.first_name}",
          :MiddleName => "#{customer.last_name}",
          :PrimaryPhone => {
              :FreeFormNumber => "#{customer.try(:patient_contacts).try(:first).try(:contact_no)}"
          },
          :PrimaryEmailAddr => {
              :Address => "#{customer.try(:email)}"
          }
      }

    end

    # Fetch qbo remote customer object
    def fetch_by_id(qbo_id)
      begin
        @qbo_api.get(:customer, qbo_id)['Id'] rescue nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Fetch all qbo customer remote object
    def fetch_all_from_qbo
      begin
        result = []
        @qbo_api.all(:customers) { |customer| result.push(customer) }
        result
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end

    end

    # Create customer object on QBO
    def create_on_qbo(customer)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(customer.company)
        response = @qbo_api.create(:customer, payload: JSON.parse(set_qbo_attributes_hash(customer).to_json))
        customer.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(customer, 'Successfully created on QBO', 'create', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(customer, error.message, 'create', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(customer, error.message, 'create', true, logs)
      end


    end

    # Update customer object on QBO
    def update_on_qbo(qbo_id, customer)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(customer.company)
        response = @qbo_api.update(:customer, id: qbo_id, payload: JSON.parse(set_qbo_attributes_hash(customer).to_json))
        customer.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(customer, 'Successfully updated on QBO', 'update', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(customer, error.message, 'update', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(customer, error.message, 'update', true, logs)
      end

    end

    # Delete customer object on QBO
    def delete_on_qbo(qbo_id)
      begin
        @customer_service.delete(@customer_service.fetch_by_id(qbo_id))
      rescue SocketError
        sleep 5
        retry
      end

    end

    # find item by name on QBO
    def fetch_by_name(customer)
      begin
        result = @qbo_api.query("SELECT * FROM Customer WHERE GivenName='#{customer.first_name}' && MiddleName='#{customer.last_name}' ")
        result = result.present? ? result[0]['Id'] : nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

  end
end