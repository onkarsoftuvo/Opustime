class AddPasswordToCompany < ActiveRecord::Migration
  def change
    remove_column :companies , :password
    add_column :companies , :password_salt , :string
    add_column :companies , :password_hash , :string
  end
end
