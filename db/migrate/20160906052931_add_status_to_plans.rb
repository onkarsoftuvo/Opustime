class AddStatusToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :status, :boolean, :default => true
  end
end
