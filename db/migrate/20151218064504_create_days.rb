class CreateDays < ActiveRecord::Migration
  def change
    create_table :days do |t|
      t.string :day_name ,limit:20
      t.string :start_hr ,limit:5
      t.string :start_min ,limit:5
      t.string :end_hr ,limit:5
      t.string :end_min ,limit:5
      t.boolean :is_selected , default:false
      t.references :practitioner_avail, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
