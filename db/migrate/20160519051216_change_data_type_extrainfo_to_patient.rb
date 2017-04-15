class ChangeDataTypeExtrainfoToPatient < ActiveRecord::Migration
  def change
    change_column :patients , :extra_info , :text
  end
end
