class RenameColumnContactnoToContactNo < ActiveRecord::Migration
  def change
    rename_column :contact_nos , :contact_no , :contact_number 
  end
end
