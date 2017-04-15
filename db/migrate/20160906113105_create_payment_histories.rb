class CreatePaymentHistories < ActiveRecord::Migration
  def change
    create_table :payment_histories do |t|
      t.integer :amount
      t.integer :paymentable_id
      t.string :paymentable_type
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
