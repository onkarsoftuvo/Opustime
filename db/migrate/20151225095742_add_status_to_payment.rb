class AddStatusToPayment < ActiveRecord::Migration
  def change
    add_column :payments, :status, :boolean , default: true
  end
end
