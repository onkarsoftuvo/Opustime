class RemoveColumnSubCategoryToReferralType < ActiveRecord::Migration
  def change
  	remove_column :referral_types, :referral_sub_category
  end
end
