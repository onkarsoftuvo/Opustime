class AddColumnToSmsNumber < ActiveRecord::Migration
  def change
  	add_column :sms_numbers , :is_trail , :boolean , :default=> true
  end
end
