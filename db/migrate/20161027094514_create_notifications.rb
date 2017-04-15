class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :initiatable, :polymorphic => true
      t.references :targetable, :polymorphic => true
      t.text :payload
      t.text :message
      t.boolean :is_open, :default => false
      t.timestamps null: false
    end
  end
end
