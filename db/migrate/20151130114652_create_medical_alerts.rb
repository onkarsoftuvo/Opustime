class CreateMedicalAlerts < ActiveRecord::Migration
  def change
    create_table :medical_alerts do |t|
      t.string :alertName
      t.references :patient, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
