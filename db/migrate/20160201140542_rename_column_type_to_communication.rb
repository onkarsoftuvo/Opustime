class RenameColumnTypeToCommunication < ActiveRecord::Migration
  def change
    rename_column :communications , :type , :comm_type 
  end
end
