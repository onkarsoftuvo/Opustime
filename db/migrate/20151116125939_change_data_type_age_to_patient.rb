class ChangeDataTypeAgeToPatient < ActiveRecord::Migration
  def change
    change_column :patients , :age , :string
  end
end
