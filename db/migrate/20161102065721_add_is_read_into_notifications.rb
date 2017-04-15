class AddIsReadIntoNotifications < ActiveRecord::Migration
  def self.up
      add_column :notifications,:is_read,:boolean,:default => false
  end

  def self.down
    remove_column :notifications,:is_read,:boolean,:default => false
  end
end
