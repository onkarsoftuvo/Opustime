class AddColumnDiscounttypeToInvoiceItem < ActiveRecord::Migration
  def change
    add_column :invoice_items, :discount_type_percentage, :boolean , :default=> true
  end
end
