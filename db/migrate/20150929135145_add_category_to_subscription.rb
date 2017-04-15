class AddCategoryToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions , :category , :string
  end
end
