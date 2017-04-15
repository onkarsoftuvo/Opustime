class AddColumnTaxRateToInvoiceItem < ActiveRecord::Migration
  def change
    add_column :invoice_items , :tax_amount , :string
  end
end
