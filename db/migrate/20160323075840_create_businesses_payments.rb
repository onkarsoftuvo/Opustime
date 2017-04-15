class CreateBusinessesPayments < ActiveRecord::Migration
  def change
    create_table :businesses_payments do |t|
      t.references :business, index: true, foreign_key: true
      t.references :payment, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
