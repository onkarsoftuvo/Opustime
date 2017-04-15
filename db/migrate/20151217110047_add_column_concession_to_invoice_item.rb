class AddColumnConcessionToInvoiceItem < ActiveRecord::Migration
  def change
    add_column :invoice_items, :concession, :string , limit: 20
  end
end
