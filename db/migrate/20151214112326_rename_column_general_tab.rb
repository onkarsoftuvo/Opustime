class RenameColumnGeneralTab < ActiveRecord::Migration
  def change
    rename_column :general_tabs , :CurrentDate , :current_date
  end
end
