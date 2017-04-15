class RenameColumnAppntTimeToAppointment < ActiveRecord::Migration
  def change
    rename_column :appointments , :appnt_time , :appnt_time_start
    add_column :appointments , :appnt_time_end , :time
  end
end
