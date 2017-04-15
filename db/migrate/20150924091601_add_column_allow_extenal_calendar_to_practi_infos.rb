class AddColumnAllowExtenalCalendarToPractiInfos < ActiveRecord::Migration
  def change
    add_column :practi_infos, :allow_external_calendar, :boolean , :default=> false
  end
end
