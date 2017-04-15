class RenameColumnbusinessToInvoice < ActiveRecord::Migration
  def change
    rename_column :invoices , :business , :businessid
  end
end
