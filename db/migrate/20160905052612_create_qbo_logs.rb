class CreateQboLogs < ActiveRecord::Migration
  def change
    create_table :qbo_logs do |t|
      t.references :loggable,:polymorphic=>true
      t.string :action_name
      t.text :message
      t.boolean :status
      t.timestamps null: false
    end
  end
end
