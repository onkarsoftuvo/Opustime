class CreateAnnouncemsgPermissions < ActiveRecord::Migration
  def change
    create_table :announcemsg_permissions do |t|
      t.text :announcemsg_crud
      t.text :announcemsg_comment
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
