class CreateTempSections < ActiveRecord::Migration
  def change
    create_table :temp_sections do |t|
      t.string :name
      t.references :template_note, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
