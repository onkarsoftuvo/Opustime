class AddColumnsToXeroSession < ActiveRecord::Migration
  def change
    add_column :xero_sessions , :request_token , :string
    add_column :xero_sessions , :request_secret , :string
  end
end
