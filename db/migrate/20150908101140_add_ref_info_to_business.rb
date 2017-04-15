class AddRefInfoToBusiness < ActiveRecord::Migration
  def change
    remove_column :businesses , :reg_info
    add_column :businesses , :reg_name , :string
    add_column :businesses , :reg_number , :string
  end
end
