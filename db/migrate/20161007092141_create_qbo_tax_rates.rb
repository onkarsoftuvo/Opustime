class CreateQboTaxRates < ActiveRecord::Migration
  def change
    create_table :qbo_tax_rates do |t|
      t.references :tax_setting, index: true, foreign_key: true
      t.float :amount

      t.timestamps null: false
    end
  end
end
