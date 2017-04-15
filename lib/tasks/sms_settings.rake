task :add_default_group => :enviroment do
  sms_group = SmsGroup.create(name: 'Default', incoming_sms: 1)
end

task :update_existing_company_sms_group => :environment do
  companies = Company.all
  # default_sms_group = SmsGroup.find_by(name: 'Default')
  if companies.present?
    companies.each do |comp|
      sms_group_country = SmsGroupCountry.where(country: comp.country).last
      if sms_group_country.present?
        comp.update_column(:sms_group_id, sms_group_country.sms_group_id)
      else
        # comp.update_column(:sms_group_id, default_sms_group.id)
      end
    end
  end

end