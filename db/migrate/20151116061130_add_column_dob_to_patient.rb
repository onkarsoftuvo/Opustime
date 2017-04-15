class AddColumnDobToPatient < ActiveRecord::Migration
  def change
    remove_column :patients , :dob_day
    remove_column :patients , :dob_month
    remove_column :patients , :dob_year
    add_column :patients , :dob , :date
  end
end
