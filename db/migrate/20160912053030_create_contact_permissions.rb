class CreateContactPermissions < ActiveRecord::Migration
  def change
    create_table :contact_permissions do |t|
      t.text :contact_view
      t.text :contact_create
      t.text :contact_edit
      t.text :contact_delete
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
