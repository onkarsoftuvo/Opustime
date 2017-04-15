class AddcolumnPatientIdsToImport < ActiveRecord::Migration
  def change
  	add_column :imports , :patients_ids , :text
  end
end
