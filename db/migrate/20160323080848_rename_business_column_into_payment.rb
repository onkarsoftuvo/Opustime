class RenameBusinessColumnIntoPayment < ActiveRecord::Migration
  def change
    rename_column :payments , :business , :businessid
    change_column :payments , :businessid , :integer 
  end
end
