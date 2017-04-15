module Quickbooks
  class Bill < Quickbooks::Connection

    # Set QBO bill model attributes
    def set_qbo_attributes_hash(expense)
      expense_tax = TaxSetting.find_by_id(expense.tax)

      if expense_tax.present?
        {
            :Line => [
                {
                    :Id => '1',
                    :Description => 'Business Expense',
                    :Amount => expense.total_expense,
                    :DetailType => 'AccountBasedExpenseLineDetail',
                    :AccountBasedExpenseLineDetail =>
                        {
                            :AccountRef =>
                                {
                                    :value => "#{expense.expense_account_ref}"
                                },
                            :TaxAmount => "#{expense.tax_amount}",
                            :TaxCodeRef =>
                                {
                                    :value => expense_tax.tax_code_ref
                                }
                        }
                }
            ],
            :GlobalTaxCalculation => expense_tax.tax_code_ref.present? ? 'TaxExcluded' : 'NotApplicable',
            :VendorRef =>
                {
                    :value => "#{expense.expense_vendor.qbo_id}"
                }
        }
      else
        {
            :Line => [
                {
                    :Id => '1',
                    :Description => 'Business Expense',
                    :Amount => expense.total_expense,
                    :DetailType => 'AccountBasedExpenseLineDetail',
                    :AccountBasedExpenseLineDetail =>
                        {
                            :AccountRef =>
                                {
                                    :value => "#{expense.expense_account_ref}"
                                }
                        }
                }
            ],
            :VendorRef =>
                {
                    :value => "#{expense.expense_vendor.qbo_id}"
                }
        }
      end



    end

    # Fetch qbo remote bill object
    def fetch_by_id(qbo_id)
      begin
        @qbo_api.get(:bill, qbo_id)['Id'] rescue nil
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

    # Create bill object on QBO
    def create_on_qbo(expense)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(expense.company)
        response = @qbo_api.create(:bill, payload: JSON.parse(set_qbo_attributes_hash(expense).to_json))
        expense.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(expense, 'Successfully created on QBO', 'create', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(expense, error.message, 'create', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(expense, error.message, 'create', true, logs)
      end

    end

    # Update bill object on QBO
    def update_on_qbo(qbo_id, expense)
      attempt = 0
      begin
        logs = Quickbooks::Logs.new(expense.company)
        response = @qbo_api.update(:bill, id: qbo_id, payload: JSON.parse(set_qbo_attributes_hash(expense).to_json))
        expense.update_column('qbo_id', response['Id']) if response.present? && response['Id'].present?
        logs.update_success_log(expense, 'Successfully updated on QBO', 'update', false, logs)
      rescue Faraday::ConnectionFailed => error
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(expense, error.message, 'update', true, logs)
      rescue QboApi::BadRequest => error
        logs.update_error_log(expense, error.message, 'update', true, logs)
      end

    end

    # Delete bill object on QBO
    def delete_on_qbo(qbo_id, expense)
      begin
        logs = Quickbooks::Logs.new(expense.company)
        response = @qbo_api.delete(:bill, id: qbo_id)
        if response['status'].to_s.eql?('Deleted')
          logs.update_success_log(expense, 'Successfully deleted on QBO', 'delete', false, logs)
        else
          logs.update_success_log(expense, 'Not deleted on QBO', 'delete', false, logs)
        end
      rescue Faraday::ConnectionFailed
        attempt +=1
        sleep 2
        retry if attempt < 5
        logs.update_error_log(expense, error.message, 'delete', true, logs)
      rescue QboApi::BadRequest, Exception => error
        logs.update_error_log(expense, error.message, 'delete', true, logs)
      end
    end
  end
end