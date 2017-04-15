class CreateFacebookDetails < ActiveRecord::Migration
  def change
    create_table :facebook_details do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :dob
      t.string :email
      t.text :address
      t.string :city
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
