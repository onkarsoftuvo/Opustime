class AddColumnStatusToInvoicesPayment < ActiveRecord::Migration
  def change
    add_column :invoices_payments , :status , :boolean , default: true
  end
end
