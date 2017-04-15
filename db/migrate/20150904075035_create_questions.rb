class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.text :title
      t.string :q_type
      t.references :temp_section, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
