class CreateLetterTemplates < ActiveRecord::Migration
  def change
    create_table :letter_templates do |t|
      t.string :template_name
      t.string :default_email_subject
      t.text :template_body
      t.references :company, index: true, foreign_key: true
      t.boolean :status , default: true

      t.timestamps null: false
    end
  end
end
