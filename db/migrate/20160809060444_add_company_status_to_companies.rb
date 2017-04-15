class AddCompanyStatusToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :company_status, :string
  end
end
