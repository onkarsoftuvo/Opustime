class ChangeDataTypeToBillableItem < ActiveRecord::Migration
  def change
    change_column :billable_items , :price , :string
    change_column :billable_items , :tax , :string
  end
end
