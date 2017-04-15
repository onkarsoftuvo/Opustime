class CreatePractiInfos < ActiveRecord::Migration
  def change
    create_table :practi_infos do |t|
      t.string :designation
      t.text :desc
      t.string :services_type
      t.string :default_type
      t.string :notify_by , default: "email", null: false
      t.integer :cancel_time , default: 7, null: false
      t.boolean :is_online , default: true, null: false
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
