class CreateOwners < ActiveRecord::Migration
  def change
    create_table :owners do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password_hash
      t.string :password_salt
      t.string :role

      t.timestamps null: false
    end
  end
end
