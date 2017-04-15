class UserLastloginRemove < ActiveRecord::Migration
  def self.up
    add_column :companies, :lastlogin, :datetime
    remove_column :users, :lastlogin
  end
  def self.down
    remove_column :companies, :lastlogin
    add_column :users, :lastlogin, :datetime
  end
end
