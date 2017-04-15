class ChangeStructureToPlan < ActiveRecord::Migration
  def change
    rename_column :plans , :monthly_price , :price
    remove_column :plans , :is_selected 
    add_column :plans , :category , :string
    
  end
end
