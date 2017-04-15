class ChangeStructureToSubscription < ActiveRecord::Migration
  def change
    remove_reference :subscriptions , :plan , :index=> false
    rename_column :subscriptions , :monthly_fee , :cost
    rename_column :subscriptions , :next_billing_date , :purchase_date
    
  end
end
