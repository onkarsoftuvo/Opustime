class AddColumnXeroTaxToTaxSetting < ActiveRecord::Migration
  def change
    add_column :tax_settings , :xero_tax , :string
  end
end
