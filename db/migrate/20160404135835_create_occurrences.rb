class CreateOccurrences < ActiveRecord::Migration
  def change
    create_table :occurrences do |t|
      t.integer :appointment_id
      t.integer :childappointment_id

      t.timestamps null: false
    end
  end
end
