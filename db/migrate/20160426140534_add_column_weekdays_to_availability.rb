class AddColumnWeekdaysToAvailability < ActiveRecord::Migration
  def change
    add_column :availabilities, :week_days, :text
    add_column :availabilities, :unique_key , :integer
    add_column :availabilities, :series_time_stamp , :datetime
    
  end
end
