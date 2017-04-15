class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :contact_type
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :preffered_name
      t.string :occupation
      t.string :company_name
      t.string :provider_number
      t.text :phone_list
      t.string :email
      t.string :address_1
      t.string :address_2
      t.string :address_3
      t.string :city
      t.string :state
      t.integer :post_code
      t.string :country
      t.text :notes
      t.boolean :status  , default: true
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
