class AddReferenceUserIdToImport < ActiveRecord::Migration
  def up
    add_reference :imports , :user , foreign_key: true
  end
  def down
    remove_reference :imports , :user , foreign_key: true
  end
end
