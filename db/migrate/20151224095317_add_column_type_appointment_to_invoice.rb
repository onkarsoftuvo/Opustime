class AddColumnTypeAppointmentToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :type_appointment, :string , limit:25  , default:"AppointmentType"
  end
end
