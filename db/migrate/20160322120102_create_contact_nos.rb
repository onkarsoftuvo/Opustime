class CreateContactNos < ActiveRecord::Migration
  def change
    create_table :contact_nos do |t|
      t.string :contact_no
      t.string :contact_type
      t.references :contact, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
