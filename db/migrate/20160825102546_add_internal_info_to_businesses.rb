class AddInternalInfoToBusinesses < ActiveRecord::Migration
  def change
    add_column :businesses, :internal_info, :text
  end
end
