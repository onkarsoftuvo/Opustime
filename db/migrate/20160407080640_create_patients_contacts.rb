class CreatePatientsContacts < ActiveRecord::Migration
  def change
    create_table :patients_contacts do |t|
      t.references :patient, index: true, foreign_key: true
      t.references :contact, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
