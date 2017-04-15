class AddColumnBreakToPractiAvail < ActiveRecord::Migration
  def change
    add_column :practi_avails, :all_break, :text
  end
end
