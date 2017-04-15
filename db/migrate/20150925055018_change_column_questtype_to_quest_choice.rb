class ChangeColumnQuesttypeToQuestChoice < ActiveRecord::Migration
  def change
    rename_column :quest_choices , :q_type , :value 
    change_column :quest_choices , :value, :boolean , :default=> false
  end
end
