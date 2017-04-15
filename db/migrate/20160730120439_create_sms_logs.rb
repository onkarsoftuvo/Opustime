class CreateSmsLogs < ActiveRecord::Migration
  def change
    create_table :sms_logs do |t|
      t.string :contact_to
      t.string :contact_from
      t.string :sms_type
      t.datetime :delivered_on
      t.string :status
      t.references :patient, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
