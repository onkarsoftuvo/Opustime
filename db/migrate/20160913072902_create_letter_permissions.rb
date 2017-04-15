class CreateLetterPermissions < ActiveRecord::Migration
  def change
    create_table :letter_permissions do |t|
      t.text :latter_viewown
      t.text :letter_viewall
      t.text :letter_delete
      t.references :owner, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
