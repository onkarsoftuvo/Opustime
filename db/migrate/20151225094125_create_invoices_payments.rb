class CreateInvoicesPayments < ActiveRecord::Migration
  def change
    create_table :invoices_payments do |t|
      t.decimal :amount
      t.references :payment
      t.references :invoice
      t.timestamps null: false
    end
    add_index :invoices_payments, [:payment_id, :invoice_id]
    add_index :invoices_payments, :invoice_id
  end
end
