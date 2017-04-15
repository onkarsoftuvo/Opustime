class AddDescriptionToFileAttachment < ActiveRecord::Migration
  def change
    add_column :file_attachments, :description, :string
  end
end
