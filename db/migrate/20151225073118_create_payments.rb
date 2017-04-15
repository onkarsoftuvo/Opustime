class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.string :business , limit: 30 , null: false
      t.datetime :payment_date
      t.text :payment_source
      t.text :notes
      t.references :patient, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
