class AddAuthorizenetCustomerInfoIntoCompany < ActiveRecord::Migration
  def change
    change_table :companies do |t|
      t.string :authorizenet_profile_id
      t.string :authorizenet_payment_profile_id
    end

    change_table :subscriptions do |t|
      t.string :authorizenet_subscription_id
    end
  end
end
