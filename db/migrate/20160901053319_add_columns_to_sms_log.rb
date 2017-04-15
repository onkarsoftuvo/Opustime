class AddColumnsToSmsLog < ActiveRecord::Migration
  def change
  	add_column :sms_logs , :object_id , :string
  	add_column :sms_logs , :object_type , :string
  end
end
