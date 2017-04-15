class AddStatusIntoOwners < ActiveRecord::Migration
  def self.up
      add_column :owners,:status,:boolean,:default => false
  end

  def self.down
    remove_column :owners,:status,:boolean
  end
end
