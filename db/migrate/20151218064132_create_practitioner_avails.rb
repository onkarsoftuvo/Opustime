class CreatePractitionerAvails < ActiveRecord::Migration
  def change
    create_table :practitioner_avails do |t|
      t.string :business_id , null:false , limit: 15
      t.string :business_name , null:false , limit: 60
      t.references :practi_info, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
