class CreateFileAttachments < ActiveRecord::Migration
  def change
    create_table :file_attachments do |t|
      t.references :patient, index: true, foreign_key: true
      t.attachment :avatar
      t.timestamps null: false
    end
  end
end
