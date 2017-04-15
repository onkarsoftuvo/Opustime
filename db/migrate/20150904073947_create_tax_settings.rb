class CreateTaxSettings < ActiveRecord::Migration
  def change
    create_table :tax_settings do |t|
      t.string :name
      t.integer :amount
      t.references :company, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
