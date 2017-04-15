class CreateRecalls < ActiveRecord::Migration
  def change
    create_table :recalls do |t|
      t.date :recall_on_date
      t.text :notes
      t.boolean :is_selected , default: false
      t.date :recall_set_date
      t.references :patient, index: true, foreign_key: true
      t.boolean :status , default: true

      t.timestamps null: false
    end
  end
end
