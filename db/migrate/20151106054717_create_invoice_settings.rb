class CreateInvoiceSettings < ActiveRecord::Migration
  def change
    create_table :invoice_settings do |t|
      t.string :title
      t.integer :starting_invoice_number
      t.string :extra_bussiness_information
      t.string :offer_text
      t.string :default_notes
      t.boolean :show_business_info
      t.boolean :hide_business_details
      t.boolean :include_next_appointment
      t.boolean :status , default: true
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
