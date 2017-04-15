class RemoveColumnPhoneListFromPatient < ActiveRecord::Migration
  def change
    remove_column :patients , :phone_list
  end
end
