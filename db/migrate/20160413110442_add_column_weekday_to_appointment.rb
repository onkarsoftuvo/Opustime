class AddColumnWeekdayToAppointment < ActiveRecord::Migration
  def change
    add_column :appointments , :week_days , :text  
  end
end
