module Quickbooks
  class Account < Quickbooks::Connection

    # find all QBO accounts
    def fetch_all_from_qbo
      begin
        result = []
        @qbo_api.all(:accounts) { |record| result.push(record) }
        group_accounts = result.group_by { |record| record['AccountType'] }.values
        result.clear
        group_accounts.each do |group_account|
          result.push({"#{group_account[0]['AccountType']}" => group_account})
        end
        result
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end

    end


    def find_income_and_expense_accounts_from_remote
      begin
        response = []
        result = @qbo_api.query("SELECT * FROM Account WHERE AccountType='Expense' ") rescue []
        response.push({'Expense' => result.sort_by { |record| record['Id'].to_i }}) unless result.blank?
        result = @qbo_api.query("SELECT * FROM Account WHERE AccountType='Income' ") rescue []
        response.push({'Income' => result.sort_by { |record| record['Id'].to_i }}) unless result.blank?
        return response
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end


    def find_by_account_type_from_db(account_type,company_id)
      result = QboAccount.select('id,account_ref,account_type,account_name').where('account_type=? && company_id=?',account_type,company_id)
      result.each_with_index { |record, index| result[index]=record.as_json }
      result.each_with_index do |record, index|
        record.clone.each do |key, val|
          record['Id'] = val.to_s if key.to_s.eql?('account_ref')
          record['Name'] = val if key.to_s.eql?('account_name')
        end
        result[index] = record.except!('account_ref', 'account_type', 'account_name', 'id')
      end
      result
    end

    def find_expense_accounts
      begin
        response = []
        result = @qbo_api.query("SELECT * FROM Account WHERE AccountType='Expense' ") rescue []
        response.push({'Expense' => result.sort_by { |record| record['Id'].to_i }}) unless result.blank?
        response
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end


    def find_by_account_type_from_remote(name)
      begin
        @qbo_api.query("SELECT * FROM Account WHERE AccountType='#{name}' ")
      rescue Faraday::ConnectionFailed
        sleep 5
        retry
      end
    end

  end
end