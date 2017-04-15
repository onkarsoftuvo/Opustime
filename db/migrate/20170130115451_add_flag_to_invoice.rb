class AddFlagToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices  , :use_credit_balance , :boolean , :default => false
  end
end
