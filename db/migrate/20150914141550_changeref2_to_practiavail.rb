class Changeref2ToPractiavail < ActiveRecord::Migration
  def change
    add_column :businesses , :practi_info_id ,:integer 
    add_index :businesses ,  :practi_info_id
  end
end
