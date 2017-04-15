class ChangeDataTypeAdjusteeAtToProductStock < ActiveRecord::Migration
  def change
    change_column :product_stocks , :adjusted_at , :string
  end
end
