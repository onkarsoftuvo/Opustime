class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.date :issue_date , null: false
      t.date :close_date
      t.string :business ,limit:20
      t.string :patient ,limit:20
      t.string :appointment ,limit:20
      t.text :invoice_to
      t.text :extra_patient_info
      t.text :notes
      t.float :total_discount
      t.float :subtotal
      t.float :tax
      t.float :invoice_amount
      t.float :outstanding_balance
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
