class AddColumnStatusAndAuther < ActiveRecord::Migration
  def change
    add_column :letters , :status , :boolean , :default=> true
    add_column :letters , :auther_id , :string , limit: 50
  end
end
