class AddLogotoPatient < ActiveRecord::Migration
  def change
    add_attachment :patients , :profile_pic , :default=> nil
  end
end
