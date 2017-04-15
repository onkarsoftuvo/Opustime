class CreateContactTabs < ActiveRecord::Migration
  def change
    create_table :contact_tabs do |t|
      t.string :FullName , :default=> "Contact.FullName" , limit: 30
      t.string :Title , :default=> "Contact.Title" , limit: 30
      t.string :FirstName , :default=> "Contact.FirstName" , limit: 30
      t.string :LastName , :default=> "Contact.LastName" , limit: 30
      t.string :PreferredName , :default=> "Contact.PreferredName" , limit: 30
      t.string :CompanyName , :default=> "Contact.CompanyName" , limit: 30
      t.string :MobileNumber , :default=> "Contact.MobileNumber" , limit: 30
      t.string :HomeNumber , :default=> "Contact.HomeNumber" , limit: 30
      t.string :WorkNumber , :default=> "Contact.WorkNumber" , limit: 30
      t.string :FaxNumber , :default=> "Contact.FaxNumber" , limit: 30
      t.string :OtherNumber , :default=> "Contact.OtherNumber" , limit: 30
      t.string :Email , :default=> "Contact.Email" , limit: 30
      t.string :Address , :default=> "Contact.Address" , limit: 30
      t.string :City , :default=> "Contact.City" , limit: 30
      t.string :State , :default=> "Contact.State" , limit: 30
      t.string :PostCode , :default=> "Contact.PostCode" , limit: 30
      t.string :Country , :default=> "Contact.Country" , limit: 30
      t.string :Occupation , :default=> "Contact.Occupation" , limit: 30
      t.string :Notes , :default=> "Contact.Notes" , limit: 30
      t.string :ProviderNumber , :default=> "Contact.ProviderNumber" , limit: 30

      t.timestamps null: false
    end
  end
end
