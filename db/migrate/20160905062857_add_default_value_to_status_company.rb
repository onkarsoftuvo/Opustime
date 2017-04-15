class AddDefaultValueToStatusCompany < ActiveRecord::Migration
  def change
  	change_column :companies, :company_status , :string, :default => COMPANY_STATUS[0]
  end
end
