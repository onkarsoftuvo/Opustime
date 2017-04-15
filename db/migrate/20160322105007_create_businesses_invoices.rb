class CreateBusinessesInvoices < ActiveRecord::Migration
  def change
    create_table :businesses_invoices do |t|
      t.references :business, index: true, foreign_key: true
      t.references :invoice, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
