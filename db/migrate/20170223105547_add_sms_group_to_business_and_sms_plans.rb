class AddSmsGroupToBusinessAndSmsPlans < ActiveRecord::Migration
  def change
    add_column :companies,:sms_group_id, :integer
    add_reference :sms_plans, :sms_group, index: true
  end
end
