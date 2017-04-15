class RemoveColumnToBillableItem < ActiveRecord::Migration
  def change
    remove_column :billable_items ,:concession_price
  end
end
