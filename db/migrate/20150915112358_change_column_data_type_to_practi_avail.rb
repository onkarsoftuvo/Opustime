class ChangeColumnDataTypeToPractiAvail < ActiveRecord::Migration
  def change
    change_column :practi_avails , :start_hr , :string
    change_column :practi_avails , :start_min , :string
    change_column :practi_avails , :end_hr , :string
    change_column :practi_avails , :end_min , :string
    
    change_column :practi_breaks , :start_hr , :string
    change_column :practi_breaks , :start_min , :string
    change_column :practi_breaks , :end_hr , :string
    change_column :practi_breaks , :end_min , :string
  end
end
