class CreatePaymentTypesPayments < ActiveRecord::Migration
  def change
    create_table :payment_types_payments do |t|
      t.float :amount
      t.references :payment_type, index: true, foreign_key: true
      t.references :payment, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
