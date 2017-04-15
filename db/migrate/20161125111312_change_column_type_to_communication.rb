class ChangeColumnTypeToCommunication < ActiveRecord::Migration
  def change
    change_column :communications , :category , :text
  end
end
