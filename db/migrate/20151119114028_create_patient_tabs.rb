class CreatePatientTabs < ActiveRecord::Migration
  def change
    create_table :patient_tabs do |t|
      t.string :FullName  , :default=>"Patient.FullName" , :limit=> 30
      t.string :Title , :default=>"Patient.Title" , :limit=> 30
      t.string :FirstName , :default=>"Patient.FirstName" , :limit=> 40
      t.string :LastName , :default=>"Patient.LastName" , :limit=> 40
      t.string :MobileNumber , :default=>"Patient.MobileNumber" , :limit=> 50
      t.string :HomeNumber , :default=>"Patient.HomeNumber" , :limit=> 40
      t.string :WorkNumber , :default=>"Patient.WorkNumber" , :limit=> 40
      t.string :FaxNumber , :default=>"Patient.FaxNumber" , :limit=> 40
      t.string :OtherNumber , :default=>"Patient.OtherNumber" , :limit=> 50
      t.string :Email , :default=>"Patient.Email" , :limit=> 30
      t.string :Address , :default=>"Patient.Address" , :limit=> 40
      t.string :City , :default=>"Patient.City" , :limit=> 30
      t.string :PostCode , :default=>"Patient.PostCode" , :limit=> 40
      t.string :State , :default=>"Patient.State" , :limit=> 30
      t.string :Country , :default=>"Patient.Country" , :limit=> 30
      t.string :DateOfBirth , :default=>"Patient.DateOfBirth" , :limit=> 50
      t.string :Gender , :default=>"Patient.Gender" , :limit=> 30
      t.string :Occupation , :default=>"Patient.Occupation" , :limit=> 30
      t.string :EmergencyContact , :default=>"Patient.EmergencyContact" , :limit=> 40
      t.string :ReferralSource , :default=>"Patient.ReferralSource" , :limit=> 40
      t.string :MedicareNumber , :default=>"Patient.MedicareNumber" , :limit=> 40
      t.string :OldReferenceId , :default=>"Patient.OldReferenceId" , :limit=> 40
      t.string :IdentificationNumber , :default=>"Patient.IdentificationNumber" , :limit=> 50
      t.string :Notes , :default=>"Patient.Notes" , :limit=> 30
      t.string :FirstAppointmentDate , :default=>"Patient.FirstAppointmentDate" , :limit=> 50
      t.string :FirstAppointmentTime , :default=>"Patient.FirstAppointmentTime" , :limit=> 50
      t.string :MostRecentAppointmentDate , :default=>"Patient.MostRecentAppointmentDate" , :limit=> 50
      t.string :MostRecentAppointmentTime , :default=>"Patient.MostRecentAppointmentTime" , :limit=> 50
      t.string :NextAppointmentDate , :default=>"Patient.NextAppointmentDate" , :limit=> 50
      t.string :NextAppointmentTime , :default=>"Patient.NextAppointmentTime" , :limit=> 50

      t.timestamps null: false
    end
  end
end
