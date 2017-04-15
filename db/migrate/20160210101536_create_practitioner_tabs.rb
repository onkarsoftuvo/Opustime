class CreatePractitionerTabs < ActiveRecord::Migration
  def change
    create_table :practitioner_tabs do |t|
      t.string :full_name, :default=>"Practitioner.FullName" , limit:35 
      t.string :full_name_with_title , :default=>"Practitioner.FullNameWithTitle" , limit:30
      t.string :title, :default=>"Practitioner.Title" , limit:30
      t.string :first_name , :default=>"Practitioner.FirstName" , limit:25
      t.string :last_name , :default=>"Practitioner.LastName" , limit:25
      t.string :designation , :default=>"Practitioner.Designation" , limit:35
      t.string :email, :default=>"Practitioner.Email" , limit:35
      t.string :mobile_number, :default=>"Practitioner.MobileNumber" , limit:30
      t.string :home_number, :default=>"Practitioner.HomeNumber" , limit:30
      t.string :work_number, :default=>"Practitioner.WorkNumber" , limit:30
      t.string :fax_number, :default=>"Practitioner.FaxNumber" , limit:30
      t.string :other_number, :default=>"Practitioner.OtherNumber" , limit:30

      t.timestamps null: false
    end
  end
end
