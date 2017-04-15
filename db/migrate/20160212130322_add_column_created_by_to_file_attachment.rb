class AddColumnCreatedByToFileAttachment < ActiveRecord::Migration
  def change
    add_column :file_attachments , :created_by , :string , :limit=> 25
  end
end
