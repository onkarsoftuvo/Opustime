class RenameColumnSourceItemToInvoiceItem < ActiveRecord::Migration
  def change
  	rename_column :invoice_items  , :source_item , :item_id
  end
end
