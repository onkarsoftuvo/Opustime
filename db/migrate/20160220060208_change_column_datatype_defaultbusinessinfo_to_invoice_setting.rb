class ChangeColumnDatatypeDefaultbusinessinfoToInvoiceSetting < ActiveRecord::Migration
  def change
    change_column :invoice_settings , :extra_bussiness_information , :text
  end
end
