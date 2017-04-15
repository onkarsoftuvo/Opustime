class CreateXeroSessions < ActiveRecord::Migration
  def change
    create_table :xero_sessions do |t|
      t.boolean :is_connected , default: false
      t.string :auth_token , limit: 25
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
