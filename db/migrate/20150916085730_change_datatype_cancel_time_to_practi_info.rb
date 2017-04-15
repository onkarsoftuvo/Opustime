class ChangeDatatypeCancelTimeToPractiInfo < ActiveRecord::Migration
  def change
    change_column :practi_infos , :cancel_time , :string
  end
end
