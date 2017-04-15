class AddColumnsCreatorAndUpdatorToInvoice < ActiveRecord::Migration
  def change
  	add_column :invoices, :creater_id, :integer
    add_column :invoices, :creater_type, :string
    add_column :invoices, :updater_id, :integer
    add_column :invoices, :updater_type, :string
  end
end
