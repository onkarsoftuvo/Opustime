class AddColumnXeroCodeToProduct < ActiveRecord::Migration
  def change
    add_column :products, :xero_code, :string
  end
end
