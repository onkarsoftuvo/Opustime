class AddColumnNameToPermission < ActiveRecord::Migration
  def change
    add_column :permissions , :name ,:string
  end
end
