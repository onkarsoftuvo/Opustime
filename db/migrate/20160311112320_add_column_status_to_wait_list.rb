class AddColumnStatusToWaitList < ActiveRecord::Migration
  def change
    add_column :wait_lists , :status , :boolean , :default=> true
  end
end
