class CreateReferringDoctorTabs < ActiveRecord::Migration
  def change
    create_table :referring_doctor_tabs do |t|
      t.string :FullName , :default=> "ReferringDoctor.FullName" , :limit=> 35
      t.string :Title , :default=> "ReferringDoctor.Title" , :limit=> 35
      t.string :FirstName , :default=> "ReferringDoctor.FirstName" , :limit=> 35
      t.string :LastName , :default=> "ReferringDoctor.LastName" , :limit=> 35
      t.string :PreferredName , :default=> "ReferringDoctor.PreferredName" , :limit=> 35
      t.string :CompanyName , :default=> "ReferringDoctor.CompanyName" , :limit=> 35
      t.string :MobileNumber , :default=> "ReferringDoctor.MobileNumber" , :limit=> 35
      t.string :HomeNumber , :default=> "ReferringDoctor.HomeNumber" , :limit=> 35
      t.string :WorkNumber , :default=> "ReferringDoctor.WorkNumber" , :limit=> 35
      t.string :FaxNumber , :default=> "ReferringDoctor.Faxnumber" , :limit=> 35
      t.string :OtherNumber , :default=> "ReferringDoctor.OtherNumber" , :limit=> 35
      t.string :Email , :default=> "ReferringDoctor.Email" , :limit=> 30
      t.string :Address , :default=> "ReferringDoctor.Address" , :limit=> 35
      t.string :City , :default=> "ReferringDoctor.City" , :limit=> 35
      t.string :State , :default=> "ReferringDoctor.State" , :limit=> 35
      t.string :PostCode , :default=> "ReferringDoctor.PostCode" , :limit=> 35
      t.string :Country , :default=> "ReferringDoctor.Country" , :limit=> 35
      t.string :Occupation , :default=> "ReferringDoctor.Occupation" , :limit=> 35
      t.string :Notes , :default=> "ReferringDoctor.Notes" , :limit=> 30
      t.string :ProviderNumber , :default=> "ReferringDoctor.ProviderNumber" , :limit=> 45

      t.timestamps null: false
    end
  end
end
