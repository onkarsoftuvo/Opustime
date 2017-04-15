class CreateExports < ActiveRecord::Migration
  def change
    create_table :exports do |t|
      t.string :ex_type
      t.string :ex_date_range
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
