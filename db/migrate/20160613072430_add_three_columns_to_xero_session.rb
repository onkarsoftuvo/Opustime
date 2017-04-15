class AddThreeColumnsToXeroSession < ActiveRecord::Migration
  def change
     add_column :xero_sessions , :inv_item_code , :string
     add_column :xero_sessions , :payment_code , :string
     add_column :xero_sessions , :tax_rate_code , :string
  end  
end
