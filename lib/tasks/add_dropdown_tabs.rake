# after completing first then run this
task :adding_tab_models => :environment do
  puts "You are running rake task in #{Rails.env} environment"
  PatientTab.create()
  PractitionerTab.create()
  BusinessTab.create()
  ContactTab.create()
  ReferringDoctorTab.create()
  GeneralTab.create()
  puts "Tab models have been created succesfully!" 
end

# first run this rake task
task :remove_tab_models => :environment do 
  puts "Tab model's record is removing ..... "
  puts "You are running rake task in #{Rails.env} environment"
  PatientTab.all.destroy_all if PatientTab.table_exists?
  PractitionerTab.all.destroy_all if PractitionerTab.table_exists?
  BusinessTab.all.destroy_all if BusinessTab.table_exists?
  ContactTab.all.destroy_all if ContactTab.table_exists?
  ReferringDoctorTab.all.destroy_all if ReferringDoctorTab.table_exists?
  GeneralTab.all.destroy_all if GeneralTab.table_exists?
  puts "Tab model's record has been deleted successfully. "
end
