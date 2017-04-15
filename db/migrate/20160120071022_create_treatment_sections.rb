class CreateTreatmentSections < ActiveRecord::Migration
  def change
    create_table :treatment_sections do |t|
      t.string :name 
      t.references :treatment_note, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
