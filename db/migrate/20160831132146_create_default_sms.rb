class CreateDefaultSms < ActiveRecord::Migration
  def change
    create_table :default_sms do |t|
      t.integer :sms_no
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
