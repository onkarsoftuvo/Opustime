class CreateLetterTemplatesLetters < ActiveRecord::Migration
  def change
    create_table :letter_templates_letters do |t|
      t.references :letter, index: true, foreign_key: true
      t.references :letter_template, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
