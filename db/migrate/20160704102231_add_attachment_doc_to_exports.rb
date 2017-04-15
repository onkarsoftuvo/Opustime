class AddAttachmentDocToExports < ActiveRecord::Migration
  def self.up
    change_table :exports do |t|
      t.attachment :doc
    end
  end

  def self.down
    remove_attachment :exports, :doc
  end
end
