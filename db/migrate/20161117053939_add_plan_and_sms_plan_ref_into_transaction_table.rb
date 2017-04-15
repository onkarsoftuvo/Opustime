class AddPlanAndSmsPlanRefIntoTransactionTable < ActiveRecord::Migration
  def self.up
    add_reference :authorizenet_logs,:sms_plan,:index => true
    add_reference :authorizenet_logs,:plan,:index => true
    add_column :authorizenet_logs,:response,:text
    remove_column :authorizenet_logs,:action_name
  end

  def self.down
    remove_reference :authorizenet_logs,:sms_plan,:index => true
    remove_reference :authorizenet_logs,:plan,:index => true
    remove_column :authorizenet_logs,:response,:text
    add_column :authorizenet_logs,:action_name,:text
  end
end
