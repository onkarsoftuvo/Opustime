class AddPatientRefToInvoice < ActiveRecord::Migration
  def change
    add_reference :invoices, :patient, index: true, foreign_key: true
  end
end
