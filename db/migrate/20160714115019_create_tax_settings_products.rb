class CreateTaxSettingsProducts < ActiveRecord::Migration
  def change
    create_table :tax_settings_products do |t|
      t.references :product, index: true, foreign_key: true
      t.references :tax_setting, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
