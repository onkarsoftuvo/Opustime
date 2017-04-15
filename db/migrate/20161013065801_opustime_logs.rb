class OpustimeLogs < ActiveRecord::Migration
  def self.up
    create_table :opustime_logs do |t|
      t.text :class_name
      t.text :message
      t.text :trace
      t.text :params
      t.text :target_url
      t.text :referer_url
      t.text :user_agent
      t.string :user_info
      t.string :app_name
      t.string :gateway_interface

      t.timestamps
    end
  end

  def self.down
    drop_table :opustime_logs
  end
end
