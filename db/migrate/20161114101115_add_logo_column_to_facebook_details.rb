class AddLogoColumnToFacebookDetails < ActiveRecord::Migration
  def change
    add_attachment :facebook_details, :logo
  end
end
