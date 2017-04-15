class RemoveBusinessnameToPractiavail < ActiveRecord::Migration
  def change
    remove_column :practi_avails , :business_name
  end
end
