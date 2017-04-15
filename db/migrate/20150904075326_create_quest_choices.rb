class CreateQuestChoices < ActiveRecord::Migration
  def change
    create_table :quest_choices do |t|
      t.string :title
      t.string :q_type
      t.references :question, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
