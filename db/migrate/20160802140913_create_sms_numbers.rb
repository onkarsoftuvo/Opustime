class CreateSmsNumbers < ActiveRecord::Migration
  def change
    create_table :sms_numbers do |t|
      t.text :number
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
