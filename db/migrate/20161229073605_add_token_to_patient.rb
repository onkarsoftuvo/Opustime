class AddTokenToPatient < ActiveRecord::Migration
  def change
    add_column :patients , :token , :string ,  :limit=> 30
  end
end
