class ChangePhoneListDataTypeToPatient < ActiveRecord::Migration
  def change
    change_column :patients , :phone_list , :text
  end
end
