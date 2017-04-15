class AddColumnsIntoAppointment < ActiveRecord::Migration
  def change
  	add_column :appointments , :cancellation_notes , :text
  	add_column :appointments , :cancellation_time , :datetime
  end
end
