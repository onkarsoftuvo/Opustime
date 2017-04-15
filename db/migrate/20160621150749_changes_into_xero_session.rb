class ChangesIntoXeroSession < ActiveRecord::Migration
  def change
    remove_column :xero_sessions , :auth_token 
    rename_column :xero_sessions , :request_token , :access_token
    rename_column :xero_sessions , :request_secret , :access_secret
  end
end
