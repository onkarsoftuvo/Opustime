class AddAgeToPatient < ActiveRecord::Migration
  def change
    add_column :patients, :age, :integer , default: 0
  end
end
