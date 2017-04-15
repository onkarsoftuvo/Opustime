class CreateTreatmentNotes < ActiveRecord::Migration
  def change
    create_table :treatment_notes do |t|
      t.string :template_id , limit: 20 , null:false
      t.string :appointment_id , limit: 20 
      t.boolean :save_final , default: false
      t.references :patient, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
