class RemoveColumnbusinessidToUser < ActiveRecord::Migration
  def change
    remove_column :users , :business_id
  end
end
