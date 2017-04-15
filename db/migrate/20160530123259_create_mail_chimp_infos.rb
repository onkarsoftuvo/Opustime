class CreateMailChimpInfos < ActiveRecord::Migration
  def change
    create_table :mail_chimp_infos do |t|
      t.string :key
      t.string :list_name
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
