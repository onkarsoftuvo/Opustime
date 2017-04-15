class AddFieldsIntoSubscription < ActiveRecord::Migration
  def change
    change_table :subscriptions do |t|
      t.boolean :is_trial
      t.date :end_date
    end
  end

end
