class AddInvoiceNumIntoInvoice < ActiveRecord::Migration
  def self.up
      add_column :invoices,:number,:string
      add_column :invoice_settings,:next_invoice_number,:integer
  end

  def self.down
    remove_column :invoices,:number
    remove_column :invoice_settings,:next_invoice_number,:integer
  end
end
