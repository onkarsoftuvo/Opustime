class ChangeStocklevelTypeToProductStock < ActiveRecord::Migration
  def change
    change_column :product_stocks , :stock_level , :string
  end
end
