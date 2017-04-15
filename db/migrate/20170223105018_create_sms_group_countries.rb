class CreateSmsGroupCountries < ActiveRecord::Migration
  def change
    create_table :sms_group_countries do |t|
      t.references :sms_group, index: true, foreign_key: true
      t.string :country
      t.timestamps null: false
    end
  end
end
