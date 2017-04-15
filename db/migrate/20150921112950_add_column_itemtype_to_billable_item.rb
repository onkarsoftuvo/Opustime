class AddColumnItemtypeToBillableItem < ActiveRecord::Migration
  def change
    add_column :billable_items , :item_type , :boolean , :default=> true
    add_column :billable_items , :concession_price , :text 
  end
end
