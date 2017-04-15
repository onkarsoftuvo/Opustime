class CreateSmsGroups < ActiveRecord::Migration
  def change
    create_table :sms_groups do |t|
      t.string :name
      t.boolean :incoming_message, :default => false
      t.timestamps null: false
    end
  end
end
