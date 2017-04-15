class AddCreditColumnToInvoicePayment < ActiveRecord::Migration
  def change
    add_column :invoices_payments, :credit_amount, :float , :default=> 0.0
  end
end
