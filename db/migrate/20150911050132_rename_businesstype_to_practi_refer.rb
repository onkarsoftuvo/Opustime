class RenameBusinesstypeToPractiRefer < ActiveRecord::Migration
  def change
    rename_column :practi_refers  , :business_name  , :business_id
  end
end
