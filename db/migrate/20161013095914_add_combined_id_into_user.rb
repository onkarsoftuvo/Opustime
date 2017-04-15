class AddCombinedIdIntoUser < ActiveRecord::Migration
  def change
    add_column :users,:combine_ids,:string
  end
end
