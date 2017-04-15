class CreateAppointmentTypesUsers < ActiveRecord::Migration
  def change
    create_table :appointment_types_users do |t|
      t.belongs_to :appointment_type, :index=> true
      t.belongs_to :user , :index=> true
      t.timestamps null: false
    end
  end
end
