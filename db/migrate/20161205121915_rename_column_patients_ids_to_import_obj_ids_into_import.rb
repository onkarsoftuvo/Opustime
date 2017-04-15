class RenameColumnPatientsIdsToImportObjIdsIntoImport < ActiveRecord::Migration
  def up
    rename_column :imports , :patients_ids , :imported_obj_ids
  end
  def down
    rename_column :imports ,:imported_obj_ids , :patients_ids
  end
end
