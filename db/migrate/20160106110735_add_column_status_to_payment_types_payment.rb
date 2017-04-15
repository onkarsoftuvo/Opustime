class AddColumnStatusToPaymentTypesPayment < ActiveRecord::Migration
  def change
    add_column :payment_types_payments , :status , :boolean , default: true
  end
end
