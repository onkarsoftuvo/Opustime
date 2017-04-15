class CreatePaymentPermissions < ActiveRecord::Migration
  def change
    create_table :payment_permissions do |t|
      t.text :payment_view
      t.text :payment_create
      t.text :payment_edit
      t.text :payment_delete
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
