class CreateReferralTypeSubcats < ActiveRecord::Migration
  def change
    create_table :referral_type_subcats do |t|
      t.string :sub_name
      t.references :referral_type, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
