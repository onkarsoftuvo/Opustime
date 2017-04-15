class RemoveColumnIsSelectedFromWaitListsUserAndWaitListsBusiness < ActiveRecord::Migration
  def change
    remove_column :wait_lists_users , :is_selected
    remove_column :wait_lists_businesses , :is_selected
  end
end
