class AddshowinvoicelogoToDocumentAndPrinting < ActiveRecord::Migration
  def change
    add_column :document_and_printings , :show_invoice_logo , :boolean , default: true
  end
end
