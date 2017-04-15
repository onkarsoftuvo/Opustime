class ChangeDataTypeAmountToInvoicesPayment < ActiveRecord::Migration
  def change
    change_column :invoices_payments , :amount , :float
  end
end
