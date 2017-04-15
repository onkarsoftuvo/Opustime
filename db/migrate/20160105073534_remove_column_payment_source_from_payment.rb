class RemoveColumnPaymentSourceFromPayment < ActiveRecord::Migration
  def change
    remove_column :payments , :payment_source
  end
end
