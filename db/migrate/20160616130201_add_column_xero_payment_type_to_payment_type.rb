class AddColumnXeroPaymentTypeToPaymentType < ActiveRecord::Migration
  def change
    add_column :payment_types , :xero_payment_type , :string
  end
end
