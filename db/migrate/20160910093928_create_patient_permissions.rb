class CreatePatientPermissions < ActiveRecord::Migration
  def change
    create_table :patient_permissions do |t|
      t.text :patient_view
      t.text :patient_create
      t.text :patient_edit
      t.text :patient_delete
      t.text :patient_sms
      t.text :patient_archive
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
