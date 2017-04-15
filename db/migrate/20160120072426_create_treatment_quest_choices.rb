class CreateTreatmentQuestChoices < ActiveRecord::Migration
  def change
    create_table :treatment_quest_choices do |t|
      t.string :title , limit: 100
      t.references :treatment_question, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
