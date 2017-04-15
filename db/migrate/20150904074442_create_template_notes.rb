class CreateTemplateNotes < ActiveRecord::Migration
  def change
    create_table :template_notes do |t|
      t.string :name
      t.string :title
      t.boolean :show_patient_addr , default: false, null: false
      t.boolean :show_patient_dob , default: false, null: false
      t.boolean :show_patient_medicare , default: false, null: false
      t.boolean :show_patient_occup , default: false, null: false
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
