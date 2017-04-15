class RemoveColumnRefCompanyToInvoice < ActiveRecord::Migration
  def change
    remove_foreign_key :invoices, :company
    remove_reference :invoices, :company, index: true
  end
end
