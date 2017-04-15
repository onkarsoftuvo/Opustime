class RenameColumnsBusinessTab < ActiveRecord::Migration
  def change
    rename_column :business_tabs , :Name , :name
    rename_column :business_tabs , :FullAddress , :full_address
    rename_column :business_tabs , :Address , :address
    rename_column :business_tabs , :City , :city
    rename_column :business_tabs , :State , :state
    rename_column :business_tabs , :PostCode , :post_code
    rename_column :business_tabs , :Country , :country
    rename_column :business_tabs , :RegistrationName , :registration_name
    rename_column :business_tabs , :RegistrationValue , :registration_value
    rename_column :business_tabs , :WebsiteAddress , :website_address
  end
end
