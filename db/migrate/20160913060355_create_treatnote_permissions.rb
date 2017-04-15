class CreateTreatnotePermissions < ActiveRecord::Migration
  def change
    create_table :treatnote_permissions do |t|
      t.text :treatnote_view
      t.text :treatnote_viewall
      t.text :pntfile_edit
      t.text :pntfile_delete
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
