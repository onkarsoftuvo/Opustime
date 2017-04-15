class AddColumnsToExpense < ActiveRecord::Migration
  def change
    add_reference :expenses , :user
  end
end
