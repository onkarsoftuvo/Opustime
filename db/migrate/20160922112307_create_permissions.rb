class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.string :subject_class
      t.string :action
      t.references :user_role, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
