class CreateFacebookPages < ActiveRecord::Migration
  def change
    create_table :facebook_pages do |t|
      t.string :page_id
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
