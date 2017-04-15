class CreateAvailabilities < ActiveRecord::Migration
  def change
    create_table :availabilities do |t|
      t.references :user, index: true, foreign_key: true
      t.date :avail_date
      t.datetime :avail_time_start
      t.datetime :avail_time_end
      t.text :notes
      t.boolean :status , :default=> true
      t.string :repeat
      t.integer :repeat_every
      t.integer :ends_after

      t.timestamps null: false
    end
  end
end
