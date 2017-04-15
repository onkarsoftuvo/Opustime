class AddColumnsCreatorAndUpdatorToPayment < ActiveRecord::Migration
  def change
  	add_column :payments, :creater_id, :integer
    add_column :payments, :creater_type, :string
    add_column :payments, :updater_id, :integer
    add_column :payments, :updater_type, :string
  end
end
