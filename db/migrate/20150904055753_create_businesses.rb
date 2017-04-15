class CreateBusinesses < ActiveRecord::Migration
  def change
    create_table :businesses do |t|
      t.string :name
      t.text :address
      t.text :reg_info
      t.string :web_url
      t.text :contact_info
      t.boolean :online_booking , default: true , null: false
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
