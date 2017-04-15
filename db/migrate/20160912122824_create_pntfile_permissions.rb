class CreatePntfilePermissions < ActiveRecord::Migration
  def change
    create_table :pntfile_permissions do |t|
      t.text :pntfile_upload
      t.text :pntfile_viewname
      t.text :pntfile_view
      t.text :pntfile_update
      t.text :pntfile_delown
      t.text :pntfile_delall
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
