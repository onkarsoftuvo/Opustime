class AddColumnSmsTextToSmsLog < ActiveRecord::Migration
  def change
  	add_column :sms_logs , :sms_text , :text
  	add_reference :sms_logs, :user, index: true  
  	add_reference :sms_logs, :contact, index: true  
  end
end
