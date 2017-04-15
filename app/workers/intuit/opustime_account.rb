module Intuit
  class OpustimeAccount < Credentials
    def initialize(company_id, token, secret, realm_id)
      super(token,secret,realm_id)
      @company = Company.find_by_id(company_id)
    end

    def sync
      qbo_account = Quickbooks::Account.new(@token, @secret, @realm_id)
      response = qbo_account.find_income_and_expense_accounts_from_remote
      response.each do |record|
        record['Expense'].each { |expense_record| @company.qbo_accounts.create(:account_name => expense_record['Name'], :account_type => expense_record['AccountType'], :account_ref => expense_record['Id']) } if record.has_key?('Expense')
        record['Income'].each { |income_record| @company.qbo_accounts.create(:account_name => income_record['Name'], :account_type => income_record['AccountType'], :account_ref => income_record['Id']) } if record.has_key?('Income')
      end
    end
  end
end

