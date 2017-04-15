class AddColumnFbUrlToFacebookDetail < ActiveRecord::Migration
  def change
    add_column :facebook_details , :fb_url , :text
  end
end
