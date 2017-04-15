class ChangeAssociationToUserInfo < ActiveRecord::Migration
  def change
    remove_index :businesses , :practi_info_id  
  end
end
