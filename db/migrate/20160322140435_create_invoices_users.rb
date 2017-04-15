class CreateInvoicesUsers < ActiveRecord::Migration
  def change
    create_table :invoices_users do |t|
      t.references :invoice, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
