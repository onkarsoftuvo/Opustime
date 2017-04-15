class CreateQuickBookInfos < ActiveRecord::Migration
  def change
    create_table :quick_book_infos do |t|
      t.text :token
      t.text :secret
      t.string :realm_id
      t.integer :income_account_ref
      t.integer :expense_account_ref
      t.integer :tax_code_ref
      t.references :company, index: true, foreign_key: true
      t.boolean :status , :default=> true
      # Traking token expiry
      t.datetime :token_expires_at
      t.datetime :reconnect_token_at
      t.timestamps null: false
    end
  end
end
