class CreateAppointmentTypes < ActiveRecord::Migration
  def change
    create_table :appointment_types do |t|
      t.string :name
      t.text :description
      t.string :category
      t.integer :duration_time , default: 30, null: false
      t.string :billable_item
      t.string :default_note_template
      t.string :related_product
      t.string :color_code
      t.text :reminder
      t.text :prefer_practi
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
