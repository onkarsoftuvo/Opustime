class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.string :file_name
      t.string :import_type
      t.string :status
      t.boolean :show_delete
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
