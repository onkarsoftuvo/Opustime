class AddAmountAndTransactionTypeIntoAuthorizenetLog < ActiveRecord::Migration
  def self.up
    add_column :authorizenet_logs, :amount, :string
    add_column :authorizenet_logs, :transaction_type, :string
  end

  def self.down
    remove_column :authorizenet_logs, :amount, :string
    remove_column :authorizenet_logs, :transaction_type, :string
  end
end
