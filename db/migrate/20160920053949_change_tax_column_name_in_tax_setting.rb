class ChangeTaxColumnNameInTaxSetting < ActiveRecord::Migration
  def change
    add_column :tax_settings,:tax_code_ref,:string
    add_column :tax_settings,:tax_rate_data,:text
    add_column :tax_settings,:tax_code_data,:text
  end
end
