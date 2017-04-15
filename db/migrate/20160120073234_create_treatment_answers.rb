class CreateTreatmentAnswers < ActiveRecord::Migration
  def change
    create_table :treatment_answers do |t|
      t.boolean :is_selected , default: false
      t.text :ans , default: nil
      t.references :treatment_quest_choice, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
