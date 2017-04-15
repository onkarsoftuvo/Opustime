class AddColumnsToSubscription < ActiveRecord::Migration
  def change
  	add_column :subscriptions , :is_subscribed , :boolean , :default=> false
  end
end
