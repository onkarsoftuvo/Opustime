class AddColumnIsAvailToAvailability < ActiveRecord::Migration
  def change
    add_column :availabilities , :is_block , :boolean , :default=> false
    change_column :availabilities , :avail_time_start , :time
    change_column :availabilities , :avail_time_end , :time 
  end
end
