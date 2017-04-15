class ChangeDefaultValueToStatusCompany < ActiveRecord::Migration
  def change
  	change_column :companies, :company_status , :string, :default => COMPANY_STATUS[2]
  end
end
