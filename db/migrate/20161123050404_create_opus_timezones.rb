class CreateOpusTimezones < ActiveRecord::Migration
  def change
    create_table :opus_timezones do |t|
      t.string :city_name
      t.string :timezone_name
      t.string :offset
      t.text :all_cities
      t.timestamps null: false
    end
  end

end
