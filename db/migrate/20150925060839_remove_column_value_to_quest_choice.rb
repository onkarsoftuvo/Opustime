class RemoveColumnValueToQuestChoice < ActiveRecord::Migration
  def change
    remove_column :quest_choices , :value 
  end
end
