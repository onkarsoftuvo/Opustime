class CreateInvoicePermissions < ActiveRecord::Migration
  def change
    create_table :invoice_permissions do |t|
      t.text :invoice_view
      t.text :invoice_create
      t.text :invoice_edit
      t.text :invoice_delete	
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
