class CreateRecallTypes < ActiveRecord::Migration
  def change
    create_table :recall_types do |t|
      t.string :name
      t.string :period_name
      t.string :period_val
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
