class RemoveServicetypeToPractiInfo < ActiveRecord::Migration
  def change
    remove_column :practi_infos , :services_type
  end
end
