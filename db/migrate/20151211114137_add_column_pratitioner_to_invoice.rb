class AddColumnPratitionerToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :practitioner, :string
  end
end
