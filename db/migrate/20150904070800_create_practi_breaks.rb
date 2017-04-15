class CreatePractiBreaks < ActiveRecord::Migration
  def change
    create_table :practi_breaks do |t|
      t.integer :start_hr
      t.integer :start_min
      t.integer :end_hr
      t.integer :end_min
      t.references :practi_avail, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
