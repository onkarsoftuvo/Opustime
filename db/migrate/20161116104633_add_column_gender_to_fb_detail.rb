class AddColumnGenderToFbDetail < ActiveRecord::Migration
  def change
    add_column :facebook_details , :gender , :string
  end
end
