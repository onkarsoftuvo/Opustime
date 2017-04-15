class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password_hash
      t.string :password_salt
      t.boolean :is_doctor , default: false, null: false
      t.text :phone
      t.timestamp :time_zone
      t.boolean :auth_factor , default: false, null: false
      t.string :role
      t.boolean :acc_active , default: true, null: false
      t.references :business, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
