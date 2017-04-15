module Quickbooks
  class Item < Quickbooks::Connection

    # Set QBO Item model attributes
    def set_qbo_attributes_hash(item, qbo_credential)

      if item.tax_setting.present?
        {
            :Name => "#{item.name}",
            :IncomeAccountRef => {
                :value => "#{item.income_account_ref.present? ? item.income_account_ref : qbo_credential.income_account_ref }"
            },
            :ExpenseAccountRef => {
                :value => "#{item.expense_account_ref.present? ? item.expense_account_ref : qbo_credential.expense_account_ref}"
            },
            :Type => 'Service',
            :UnitPrice => item.class.to_s.eql?('Product') ? item.price_inc_tax : item.price,
            :Taxable => true,
            :SalesTaxIncluded => is_inclusive_or_exclusive(item).to_s.eql?('inclusive') ? true : false,
            :SalesTaxCodeRef => {
                :value => "#{item.tax_setting.tax_code_ref}"
            }

        }
      else
        {
            :Name => "#{item.name}",
            :IncomeAccountRef => {
                :value => "#{item.income_account_ref.present? ? item.income_account_ref : qbo_credential.income_account_ref}"
            },
            :ExpenseAccountRef => {
                :value => "#{item.expense_account_ref.present? ? item.expense_account_ref : qbo_credential.expense_account_ref}"
            },
            :Type => 'Service',
            :UnitPrice => "#{item.price}"
        }
      end

    end

    # Fetch qbo remote Item object
    def fetch_by_id(qbo_id)
      begin
        @qbo_api.get(:item, qbo_id)['Id'] rescue nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Fetch all qbo remote item objects
    def fetch_all_from_qbo
      begin
        result = @qbo_api.query('SELECT * FROM Item')
        result['QueryResponse']['Item']
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Create Item object on QBO
    def create_on_qbo(item, qbo_credential)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(item.company)
        response = @qbo_api.create(:item, payload: JSON.parse(set_qbo_attributes_hash(item, qbo_credential).to_json))
        item.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(item, 'Successfully created on QBO', 'create', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        retry if attempt < 5
        logs.update_error_log(item, error.message, 'create', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(item, error.message, 'create', true, logs)
      end

    end

    # Update Item object on QBO
    def update_on_qbo(qbo_id, item, qbo_credential)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(item.company)
        response = @qbo_api.update(:item, id: qbo_id, payload: JSON.parse(set_qbo_attributes_hash(item, qbo_credential).to_json))
        item.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(item, 'Successfully updated on QBO', 'update', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(item, error.message, 'update', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(item, error.message, 'update', true, logs)
      end

    end

    # Delete Item object on QBO
    def delete_on_qbo(qbo_id, item)
      begin
        logs = Quickbooks::Logs.new(item.company)
        response = @item_service.delete(@item_service.fetch_by_id(qbo_id))
        unless response.active?
          logs.update_success_log(item, 'Successfully deactivated on QBO', 'deactivate', false, logs)
        else
          logs.update_success_log(item, 'Not deactivated on QBO', 'deactivate', false, logs)
        end
      rescue Faraday::ConnectionFailed
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(item, error.message, 'delete', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(item, error.message, 'delete', true, logs)
      end
    end

    # find item by name on QBO
    def fetch_by_name(item)
      begin
        result = @qbo_api.query("SELECT * FROM Item WHERE Name='#{item.name}' ")
        result = result.present? ? result[0]['Id'] : nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # check is an item is tax inclusive or exclusive
    def is_inclusive_or_exclusive(item)
      if item.class.to_s.eql?('Product')
        Product.is_tax_included?(item) ? (return 'inclusive') : (return 'exclusive')
      else
        item.include_tax ? (return 'inclusive') : (return 'exclusive')
      end
    end

  end
end