class CreateAppointmentTypesBillableItems < ActiveRecord::Migration
  def change
    create_table :appointment_types_billable_items do |t|
      t.references :appointment_type, index: true, foreign_key: true
      t.references :billable_item, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
