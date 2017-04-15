class RenameColumnsReferringDoctorTab < ActiveRecord::Migration
  def change
    rename_column :referring_doctor_tabs , :FullName , :full_name
    rename_column :referring_doctor_tabs , :Title , :title
    rename_column :referring_doctor_tabs , :FirstName , :first_name
    rename_column :referring_doctor_tabs , :LastName , :last_name
    rename_column :referring_doctor_tabs , :PreferredName , :preferred_name
    rename_column :referring_doctor_tabs , :CompanyName , :company_name
    rename_column :referring_doctor_tabs , :MobileNumber , :mobile_number
    rename_column :referring_doctor_tabs , :HomeNumber , :home_number
    rename_column :referring_doctor_tabs , :WorkNumber , :work_number
    rename_column :referring_doctor_tabs , :FaxNumber , :fax_number
    rename_column :referring_doctor_tabs , :OtherNumber , :other_number
    rename_column :referring_doctor_tabs , :Email , :email
    rename_column :referring_doctor_tabs , :Address , :address
    rename_column :referring_doctor_tabs , :City , :city
    rename_column :referring_doctor_tabs , :State , :state
    rename_column :referring_doctor_tabs , :PostCode , :post_code
    rename_column :referring_doctor_tabs , :Country , :country
    rename_column :referring_doctor_tabs , :Occupation , :occupation
    rename_column :referring_doctor_tabs , :Notes , :notes
    rename_column :referring_doctor_tabs , :ProviderNumber , :provider_number
  end
end
