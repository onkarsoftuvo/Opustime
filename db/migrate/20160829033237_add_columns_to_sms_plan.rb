class AddColumnsToSmsPlan < ActiveRecord::Migration
  def change
  	add_column :sms_plans , :status , :boolean , :default => true
  	add_column :sms_plans , :notes , :string
  end
end
