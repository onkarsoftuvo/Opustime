class AddGoogleSecretTokenIntoUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :google_secret, :string
    add_column :users, :google_qr_url, :string
  end

  def self.down
    remove_column :users, :google_secret, :string
    remove_column :users, :google_qr_url, :string
  end

end
