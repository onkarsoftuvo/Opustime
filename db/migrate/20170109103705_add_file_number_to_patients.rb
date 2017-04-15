class AddFileNumberToPatients < ActiveRecord::Migration
  def change
    add_column :patients,:file_number,:string
  end
end
