class RemoveIndexbusinessidToUser < ActiveRecord::Migration
  def change
    remove_index :users, :business_id if index_exists?(:users, :business_id)
  end
end
