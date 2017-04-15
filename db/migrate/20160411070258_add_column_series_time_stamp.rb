class AddColumnSeriesTimeStamp < ActiveRecord::Migration
  def change
    add_column :appointments , :series_time_stamp , :datetime
  end
end
