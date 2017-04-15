class RenameColumnsContactTab < ActiveRecord::Migration
  def change
    rename_column :contact_tabs , :FullName , :full_name
    rename_column :contact_tabs , :Title , :title
    rename_column :contact_tabs , :FirstName , :first_name
    rename_column :contact_tabs , :LastName , :last_name
    rename_column :contact_tabs , :PreferredName , :preferred_name
    rename_column :contact_tabs , :CompanyName , :company_name
    rename_column :contact_tabs , :MobileNumber , :mobile_number
    rename_column :contact_tabs , :HomeNumber , :home_number
    rename_column :contact_tabs , :WorkNumber , :work_number
    rename_column :contact_tabs , :FaxNumber , :fax_number
    rename_column :contact_tabs , :OtherNumber , :other_number
    rename_column :contact_tabs , :Email , :email
    rename_column :contact_tabs , :Address , :address
    rename_column :contact_tabs , :City , :city
    rename_column :contact_tabs , :State , :state
    rename_column :contact_tabs , :PostCode , :post_code
    rename_column :contact_tabs , :Country , :country
    rename_column :contact_tabs , :Occupation , :occupation
    rename_column :contact_tabs , :Notes , :notes
    rename_column :contact_tabs , :ProviderNumber , :provider_number
  end
end
