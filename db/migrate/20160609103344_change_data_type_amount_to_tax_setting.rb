class ChangeDataTypeAmountToTaxSetting < ActiveRecord::Migration
  def change
    change_column :tax_settings , :amount , :float
  end
end
