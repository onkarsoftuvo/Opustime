class CreateConcessionsPatients < ActiveRecord::Migration
  def change
    create_table :concessions_patients do |t|
      t.references :patient, index: true, foreign_key: true
      t.references :concession, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
