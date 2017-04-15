class RenameColumnPatientToPatientIdToInvoice < ActiveRecord::Migration
  def change
    rename_column :invoices , :patient , :patientid
  end
end
