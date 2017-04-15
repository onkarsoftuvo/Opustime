class QboTaxesStatusAndCompanyLogs < ActiveRecord::Migration
  def change

    change_table :qbo_logs do |t|
      t.references :company
    end

    change_table :tax_settings do |t|
      # if taxes fetches from QBO then qbo_tax=>1
      t.boolean :qbo_tax,:default=>0
    end
  end
end
