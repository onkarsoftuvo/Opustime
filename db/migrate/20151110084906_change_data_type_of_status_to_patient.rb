class ChangeDataTypeOfStatusToPatient < ActiveRecord::Migration
  def change
    change_column :patients , :status , :string , default: "active"
  end
end
