class AddColumnEmailToAttempt < ActiveRecord::Migration
  def change
    add_column :attempts, :email, :string
    add_reference :attempts, :company
  end
end
