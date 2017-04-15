class CreateBusinessesPractiInfos < ActiveRecord::Migration
  def change
    create_table :businesses_practi_infos do |t|
      t.references :practi_info, index: true, foreign_key: true
      t.references :business, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
