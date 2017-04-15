class AddInvoiceReferenceIntoProductStock < ActiveRecord::Migration
  def self.up
    add_reference :product_stocks, :invoice, index: true
  end

  def self.down
    remove_reference :product_stocks, :invoice, index: true
  end
end
