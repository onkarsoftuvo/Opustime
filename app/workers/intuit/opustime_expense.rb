module Intuit
  class OpustimeExpense < Credentials
    include Intuit::VendorFinder
    def initialize(expense_id, token, secret, realm_id)
      super(token,secret,realm_id)
      # find expense as Bill on Quickbooks
      @expense = Expense.find_by_id(expense_id)
    end

    def sync
      # find or create vendor on QBO
      qbo_vendor = Quickbooks::Vendor.new(@token, @secret, @realm_id)
      vendor = @expense.expense_vendor
      # set expense business name
      business_name = ExpenseVendorsExpense.find_by(:expense_vendor_id => vendor).expense.business.name rescue nil

      # searching vendor on QBO
      search_object_id = search(qbo_vendor,vendor,business_name)
      # send data on Quickbooks
      search_object_id.present?  ? qbo_vendor.update_on_qbo(search_object_id, vendor) : qbo_vendor.create_on_qbo(vendor)
      # create Quickbooks bill object
      qbo_bill = Quickbooks::Bill.new(@token, @secret, @realm_id)
      # check expense on QBO
      remote_qbo_expense_id = qbo_bill.fetch_by_id(@expense.qbo_id)
      # send data on Quickbooks
      remote_qbo_expense_id.present? ? qbo_bill.update_on_qbo(@expense.qbo_id, @expense) : qbo_bill.create_on_qbo(@expense)
    end

    handle_asynchronously :sync, :queue => 'Intuit'

  end
end
