class CreateRecallTypesRecalls < ActiveRecord::Migration
  def change
    create_table :recall_types_recalls do |t|
      t.references :recall_type, index: true, foreign_key: true
      t.references :recall, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
