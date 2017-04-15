class CreateReferralTypes < ActiveRecord::Migration
  def change
    create_table :referral_types do |t|
      t.string :referral_source
      t.text :referral_sub_category
      t.boolean :status , default: true
      t.references :company, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
