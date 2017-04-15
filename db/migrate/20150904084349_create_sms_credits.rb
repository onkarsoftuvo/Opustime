class CreateSmsCredits < ActiveRecord::Migration
  def change
    create_table :sms_credits do |t|
      t.integer :avail_sms
      t.references :sms_setting, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
