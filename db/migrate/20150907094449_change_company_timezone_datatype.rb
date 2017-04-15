class ChangeCompanyTimezoneDatatype < ActiveRecord::Migration
  def change
    change_column :companies , :time_zone , :string
  end
end
