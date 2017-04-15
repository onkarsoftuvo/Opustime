class AddColumnsToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :information, :text
    add_column :plans, :benefits, :text
    add_column :plans, :aditional_features, :text
  end
end
