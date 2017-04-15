class CreatePractiAvails < ActiveRecord::Migration
  def change
    create_table :practi_avails do |t|
      t.string :day_name
      t.integer :start_hr
      t.integer :start_min
      t.integer :end_hr
      t.integer :end_min
      t.string :business_name
      t.references :practi_info, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
