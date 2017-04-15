class CreateAppointmentsInvoices < ActiveRecord::Migration
  def change
    create_table :appointments_invoices do |t|
      t.references :appointment, index: true, foreign_key: true
      t.references :invoice, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
