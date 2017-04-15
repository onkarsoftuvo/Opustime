class CreateAppointmentPermissions < ActiveRecord::Migration
  def change
    create_table :appointment_permissions do |t|
      t.text :apnt_view
      t.text :apnt_create
      t.text :apnt_edit
      t.text :apnt_delete
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
