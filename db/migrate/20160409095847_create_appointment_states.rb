class CreateAppointmentStates < ActiveRecord::Migration
  def change
    create_table :appointment_states do |t|
      t.references :user, index: true, foreign_key: true
      t.integer :selected_business
      t.text :selected_practitioners
      t.integer :schedule_view

      t.timestamps null: false
    end
  end
end
