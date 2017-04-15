class AddSubscriptionIdIntoSubscription < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :nmi_subscription_id, :string
    # add_column :subscriptions,:is_subscribed,:boolean,:default => false
    add_reference :subscriptions, :plan, :index => true
    add_column :subscriptions,:is_processed,:boolean,:default => false
    add_column :subscriptions, :payment_info, :text
    add_column :subscriptions,:reminders,:text
    add_column :subscriptions, :current_billing_cycle, :datetime
    add_column :subscriptions, :next_billing_cycle, :datetime
  end

  def self.down
    remove_column :subscriptions, :nmi_subscription_id
    # remove_column :subscriptions,:is_subscribed
    remove_column :subscriptions,:is_processed
    remove_column :subscriptions, :current_billing_cycle
    remove_column :subscriptions, :next_billing_cycle
    remove_column :subscriptions,:reminders
    remove_reference :subscriptions, :plan, :index => true
    remove_column :subscriptions, :payment_info

  end
end
