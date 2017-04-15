class ChangeDatatypeStatusToReferralType < ActiveRecord::Migration
  def change
    change_column :referral_types , :status , :string
  end
end
