class AddColumnBusinessTypeToBusiness < ActiveRecord::Migration
  def change
    add_column :businesses , :business_type , :string , default: BUSINESS_TYPE[0]
  end
end
