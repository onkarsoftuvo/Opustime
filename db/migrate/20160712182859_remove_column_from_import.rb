class RemoveColumnFromImport < ActiveRecord::Migration
  def change
  	remove_column :imports , :file_name
  end
end
