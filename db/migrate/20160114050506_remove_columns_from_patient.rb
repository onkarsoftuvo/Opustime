class RemoveColumnsFromPatient < ActiveRecord::Migration
  def change
    remove_column :patients , :outstanding_balance
    remove_column :patients , :credit_amount
  end
end
