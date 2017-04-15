class ChangeBusinesstypeagainToPractiRefer < ActiveRecord::Migration
  def change
    change_column :practi_refers , :business_id , :string
  end
end
