class AddCityCountryToBusiness < ActiveRecord::Migration
  def change
    add_column :businesses , :city , :string
    add_column :businesses , :state , :string
    add_column :businesses , :pin_code , :integer
    add_column :businesses , :country , :string
  end
end
