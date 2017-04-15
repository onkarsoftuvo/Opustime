class ChangeColumnAddressToContact < ActiveRecord::Migration
  def change
    remove_column :contacts , :address_1
    remove_column :contacts , :address_2
    remove_column :contacts , :address_3
    add_column :contacts , :address , :string
  end
end
