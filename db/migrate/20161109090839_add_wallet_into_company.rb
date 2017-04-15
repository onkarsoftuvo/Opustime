class AddWalletIntoCompany < ActiveRecord::Migration
  def self.up
    add_column :companies,:wallet,:float,:default => 0
  end

  def self.down
    remove_column :companies,:wallet
  end
end
