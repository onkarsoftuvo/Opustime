class CreateAvailabilitiesBusinesses < ActiveRecord::Migration
  def change
    create_table :availabilities_businesses do |t|
      t.references :availability, index: true, foreign_key: true
      t.references :business, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
