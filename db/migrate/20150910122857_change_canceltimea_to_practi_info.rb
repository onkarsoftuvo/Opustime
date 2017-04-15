class ChangeCanceltimeaToPractiInfo < ActiveRecord::Migration
  def change
    change_column :practi_infos , :cancel_time  , :integer
  end
end
