class AddColumnLogoToAccount < ActiveRecord::Migration
   def up
    add_attachment :accounts, :logo
  end

  def down
    remove_attachment :accounts, :logo
  end
end
