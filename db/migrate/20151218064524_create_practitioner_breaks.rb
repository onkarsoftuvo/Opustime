class CreatePractitionerBreaks < ActiveRecord::Migration
  def change
    create_table :practitioner_breaks do |t|
      t.string :start_hr ,limit:5
      t.string :start_min ,limit:5
      t.string :end_hr ,limit:5
      t.string :end_min ,limit:5
      t.references :day, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
