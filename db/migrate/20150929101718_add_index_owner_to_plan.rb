class AddIndexOwnerToPlan < ActiveRecord::Migration
  def change
    add_index :plans , :owner_id
  end
end
