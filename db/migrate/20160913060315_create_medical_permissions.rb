class CreateMedicalPermissions < ActiveRecord::Migration
  def change
    create_table :medical_permissions do |t|

      t.text :medical_crud
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
