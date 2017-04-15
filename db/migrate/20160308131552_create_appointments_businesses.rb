class CreateAppointmentsBusinesses < ActiveRecord::Migration
  def change
    create_table :appointments_businesses  do |t|
      t.references :appointment, index: true, foreign_key: true
      t.references :business, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
