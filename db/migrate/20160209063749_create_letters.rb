class CreateLetters < ActiveRecord::Migration
  def change
    create_table :letters do |t|
      t.string :practitioner , limit: 25
      t.string :contact , limit: 25
      t.string :business , limit: 25
      t.text :description
      t.text :content
      t.references :patient, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
