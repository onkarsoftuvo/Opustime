class AddColumnOutstandingToPatient < ActiveRecord::Migration
  def change
    add_column :patients, :outstanding_balance, :float
    add_column :patients, :credit_amount, :float
  end
end
