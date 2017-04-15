class AddColumnReferralIdToPatient < ActiveRecord::Migration
  def change
    add_column :patients , :referral_id , :integer
  end
end
