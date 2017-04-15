class AddAttachmentLogoImageToCompanies < ActiveRecord::Migration
  def self.up
    change_table :companies do |t|
      t.attachment :logo_image
    end
  end

  def self.down
    remove_attachment :companies, :logo_image
  end
end
