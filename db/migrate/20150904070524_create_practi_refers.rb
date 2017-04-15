class CreatePractiRefers < ActiveRecord::Migration
  def change
    create_table :practi_refers do |t|
      t.string :ref_type
      t.integer :number
      t.string :business_name
      t.references :practi_info, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
