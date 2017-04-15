class CreateTreatmentQuestions < ActiveRecord::Migration
  def change
    create_table :treatment_questions do |t|
      t.string :title , null:false 
      t.string :quest_type , limit:25
      t.references :treatment_section, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
