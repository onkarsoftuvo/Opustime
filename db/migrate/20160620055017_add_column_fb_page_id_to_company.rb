class AddColumnFbPageIdToCompany < ActiveRecord::Migration
  def change
    add_column :companies , :fb_page_id , :string
  end
end
