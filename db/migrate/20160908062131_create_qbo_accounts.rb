class CreateQboAccounts < ActiveRecord::Migration
  def change
    create_table :qbo_accounts do |t|
      t.references :company,:index=>true
      t.string :account_ref
      t.string :account_name
      t.string :account_type
      t.timestamps null: false
    end
  end
end
