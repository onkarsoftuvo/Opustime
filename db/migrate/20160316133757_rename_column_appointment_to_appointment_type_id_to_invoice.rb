class RenameColumnAppointmentToAppointmentTypeIdToInvoice < ActiveRecord::Migration
  def change
    rename_column :invoices , :appointment , :appointment_type_id
  end
end
