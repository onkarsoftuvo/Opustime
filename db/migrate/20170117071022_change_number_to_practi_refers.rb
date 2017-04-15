class ChangeNumberToPractiRefers < ActiveRecord::Migration
  def change
    change_column :practi_refers, :number,  :string
  end
end
