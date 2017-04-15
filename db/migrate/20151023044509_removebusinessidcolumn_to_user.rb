class RemovebusinessidcolumnToUser < ActiveRecord::Migration
  def change
    remove_foreign_key(:users, :column => :business_id)
  end
end
