class CreateUserinfoPermissions < ActiveRecord::Migration
  def change
    create_table :userinfo_permissions do |t|
      t.text :userinfo_view
      t.text :userinfo_edit
      t.text :userinfo_cru
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
