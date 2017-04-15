module Quickbooks
  class Vendor < Quickbooks::Connection

    # Set QBO vendor model attributes
    def set_qbo_attributes_hash(vendor)
      # find business name
      business_name = ExpenseVendorsExpense.find_by(:expense_vendor_id => vendor).expense.business.name
      {
          :GivenName => "#{vendor.name.capitalize}-#{business_name.to_s.capitalize}",
          :CompanyName => "#{business_name.to_s.capitalize}"
      }
    end

    # Fetch qbo remote vendor object
    def fetch_by_id(qbo_id)
      begin
        result = @qbo_api.get(:vendor, qbo_id) rescue nil
        result.present? ? (return result['Id'], result['CompanyName']) : nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Fetch all qbo remote vendor objects
    def fetch_all_from_qbo
      begin
        result = @qbo_api.query('SELECT * FROM Vendor')
        result['QueryResponse']['Vendor'][0]
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # find vendor by name on QBO
    def fetch_by_name(vendor)
      begin
        result = @qbo_api.query("SELECT * FROM Vendor WHERE GivenName='#{vendor.name}' ")
        result.present? ? (return result[0]['Id'], result[0]['CompanyName']) : nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Create vendor object on QBO
    def create_on_qbo(vendor)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(vendor.company)
        response = @qbo_api.create(:vendor, payload: JSON.parse(set_qbo_attributes_hash(vendor).to_json))
        vendor.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(vendor, 'Successfully created on QBO', 'create', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(vendor, error.message, 'create', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(vendor, error.message, 'create', true, logs)
      end

    end

    # Update vendor object on QBO
    def update_on_qbo(qbo_id, vendor)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(vendor.company)
        response = @qbo_api.update(:vendor, id: qbo_id, payload: JSON.parse(set_qbo_attributes_hash(vendor).to_json))
        vendor.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(vendor, 'Successfully updated on QBO', 'update', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(vendor, error.message, 'update', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(vendor, error.message, 'update', true, logs)
      end

    end

    # Delete vendor object on QBO
    def delete_on_qbo(qbo_id)
      # No need to delete vendor on Quickbooks
    end
  end
end