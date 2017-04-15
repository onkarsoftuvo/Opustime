class CreateTreatmentNotesTemplateNotes < ActiveRecord::Migration
  def change
    create_table :treatment_notes_template_notes do |t|
      t.references :treatment_note, index: true, foreign_key: true
      t.references :template_note, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
