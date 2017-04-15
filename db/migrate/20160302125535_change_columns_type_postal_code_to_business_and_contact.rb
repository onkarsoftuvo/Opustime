class ChangeColumnsTypePostalCodeToBusinessAndContact < ActiveRecord::Migration
  def change
    change_column :contacts , :post_code , :string
    change_column :businesses , :pin_code , :string
  end
end
