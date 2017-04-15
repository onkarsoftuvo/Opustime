class CreatePaymentTypes < ActiveRecord::Migration
  def change
    create_table :payment_types do |t|
      t.string :name
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
