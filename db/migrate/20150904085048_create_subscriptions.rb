class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :name
      t.integer :doctors_no
      t.date :next_billing_date
      t.integer :monthly_fee
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
