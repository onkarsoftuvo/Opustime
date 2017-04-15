class ChangeDataTypePostalCodeToPatient < ActiveRecord::Migration
  def change
    change_column :patients , :postal_code , :string
  end
end
