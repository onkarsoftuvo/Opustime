class CreateBusinessTabs < ActiveRecord::Migration
  def change
    create_table :business_tabs do |t|
      t.string :Name , :default=>"Business.Name" , limit:30
      t.string :FullAddress , :default=>"Business.FullAddress" , limit:40
      t.string :Address , :default=>"Business.Address" , limit:30
      t.string :City , :default=>"Business.City" , limit:30
      t.string :State , :default=>"Business.State" , limit:30
      t.string :PostCode , :default=>"Business.PostCode" , limit:30
      t.string :Country , :default=>"Business.Country" , limit:30
      t.string :RegistrationName , :default=>"Business.RegistrationName" , limit:40
      t.string :RegistrationValue , :default=>"Business.RegistrationValue" , limit:40
      t.string :WebsiteAddress , :default=>"Business.WebsiteAddress" , limit:40
      t.string :ContactInformation , :default=>"Business.ContactInformation" , limit:40

      t.timestamps null: false
    end
  end
end
