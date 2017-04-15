class AddStatusToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices , :status ,:boolean , :default=> true
  end
end
