class AddColumnConcessionnameToBillableItemsConcession < ActiveRecord::Migration
  def change
    add_column :billable_items_concessions, :name, :string
  end
end
