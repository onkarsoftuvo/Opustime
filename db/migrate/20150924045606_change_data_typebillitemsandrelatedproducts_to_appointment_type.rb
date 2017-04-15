class ChangeDataTypebillitemsandrelatedproductsToAppointmentType < ActiveRecord::Migration
  def change
    change_column :appointment_types, :billable_item , :text
    change_column :appointment_types, :related_product , :text
  end
end
