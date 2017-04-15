class RenameColumnsIntoTreatnotePermission < ActiveRecord::Migration
  def change
    rename_column :treatnote_permissions , :pntfile_edit , :edit_own
    rename_column :treatnote_permissions , :pntfile_delete , :treatnote_delete
  end
end
