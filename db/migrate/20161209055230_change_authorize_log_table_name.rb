class ChangeAuthorizeLogTableName < ActiveRecord::Migration
  def self.up
    rename_table :authorizenet_logs, :transactions
  end

  def self.down
    rename_table :transactions, :authorizenet_logs
  end
end
