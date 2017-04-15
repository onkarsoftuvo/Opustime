class AddStateToExpense < ActiveRecord::Migration
  def change
    add_column :expenses , :status , :string , :default=> "active"
    add_column :expenses , :sub_amount , :float
    add_column :expenses , :created_by , :string
  end
end
