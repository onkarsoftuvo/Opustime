class RenameToPractiAvail < ActiveRecord::Migration
  def change
    rename_column :practi_avails , :all_break  ,:cust_break
  end
end
