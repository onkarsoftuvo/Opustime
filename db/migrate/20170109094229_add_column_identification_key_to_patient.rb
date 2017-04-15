class AddColumnIdentificationKeyToPatient < ActiveRecord::Migration
  def change
    add_column :patients , :identification_key , :string , :index => true
    add_column :contacts , :identification_key , :string , :index => true
    add_column :users , :identification_key , :string , :index => true
  end
end
