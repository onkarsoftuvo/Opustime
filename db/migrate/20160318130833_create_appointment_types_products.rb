class CreateAppointmentTypesProducts < ActiveRecord::Migration
  def change
    create_table :appointment_types_products do |t|
      t.references :appointment_type, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
