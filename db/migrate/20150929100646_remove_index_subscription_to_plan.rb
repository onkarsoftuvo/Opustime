class RemoveIndexSubscriptionToPlan < ActiveRecord::Migration
  def change
    remove_foreign_key :plans , :subscription
    remove_index :plans , :subscription_id
    remove_column :plans , :subscription_id
    add_column :plans , :owner_id , :integer 
  end
end
