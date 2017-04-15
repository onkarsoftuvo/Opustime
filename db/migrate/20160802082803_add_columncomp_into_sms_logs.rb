class AddColumncompIntoSmsLogs < ActiveRecord::Migration
  def change
  	add_reference :sms_logs, :company, index: true  
  end
end
