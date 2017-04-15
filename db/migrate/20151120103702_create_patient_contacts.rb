class CreatePatientContacts < ActiveRecord::Migration
  def change
    create_table :patient_contacts do |t|
      t.string :contact_no , :limit=> 30 
      t.string :contact_type  , :limit=> 10 , :null=> false
      t.references :patient, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
