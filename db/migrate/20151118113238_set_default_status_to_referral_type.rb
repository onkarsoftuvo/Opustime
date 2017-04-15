class SetDefaultStatusToReferralType < ActiveRecord::Migration
  def change
    change_column :referral_types , :status , :string , default: "active"
  end
end
