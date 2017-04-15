class AddColumnCreditStatusToPayment < ActiveRecord::Migration
  def change
    add_column :payments , :credit_status , :boolean , :default => false
  end
end
