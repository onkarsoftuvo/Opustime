class CreateAppointmentTypesInvoices < ActiveRecord::Migration
  def change
    create_table :appointment_types_invoices do |t|
      t.references :appointment_type, index: true, foreign_key: true
      t.references :invoice, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
