class ChangeBusinesstypeToPractiRefer < ActiveRecord::Migration
  def change
    change_column :practi_refers , :business_name , :integer
  end
end
