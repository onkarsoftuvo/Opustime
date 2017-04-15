class CreateSmsSettings < ActiveRecord::Migration
  def change
    create_table :sms_settings do |t|
      t.integer :sms_alert_no
      t.string :mob_no
      t.text :email
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
