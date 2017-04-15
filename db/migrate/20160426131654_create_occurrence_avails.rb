class CreateOccurrenceAvails < ActiveRecord::Migration
  def change
    create_table :occurrence_avails do |t|
      t.integer :availability_id
      t.integer :childavailability_id

      t.timestamps null: false
    end
  end
end
