class DropTableTreatmentNoteTemplateNote < ActiveRecord::Migration
  def change
    drop_table :treatment_note_template_notes 
  end
end
