class ChangeDataTypediscountTypePercentageToInvoice < ActiveRecord::Migration
  def change
    change_column :invoice_items , :discount_type_percentage , :string
  end
end
