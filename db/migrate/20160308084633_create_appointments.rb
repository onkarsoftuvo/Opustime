class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :appointments do |t|
      t.date :appnt_date
      t.time :appnt_time
      t.string :repeat_by
      t.integer :repeat_start
      t.integer :repeat_end
      t.text :notes
      t.references :user, index: true, foreign_key: true
      t.references :patient, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
