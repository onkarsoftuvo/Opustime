class ChangeColumnDatatypenoteandoffertextToInvoiceSetting < ActiveRecord::Migration
  def change
    change_column :invoice_settings , :offer_text , :text
    change_column :invoice_settings , :default_notes , :text
  end
end
