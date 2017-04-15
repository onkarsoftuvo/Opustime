class CsvImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: true

  def perform(company)
    @import_data = CSV.parse(File.read('public/import_files/patientDataToExport.csv'), :headers => true, :col_sep => ";")
    transformed_data = @import_data.map { |row| row.to_hash }
    # raise transformed_data.first['first_name'].inspect
    transformed_data.each do |import|
      # raise import.inspect
      patient_data = serialize_patient_data_csv(import,company)
      patient = Patient.find_or_initialize_by(patient_data)
      if patient.save(validate: false)
        phone_type = ['home', 'work']
        phone_type.each do |type|
          unless import["#{type}"].blank?
            contact_data = {}
            contact_data['contact_no'] = import["#{type}"]
            contact_data['contact_type'] = type
            contact_data['patient_id'] = patient.id
            contact = PatientContact.find_or_initialize_by(contact_data)
            contact.save(validate: false)
          end
        end
      end
    end
  end

  def serialize_patient_data_csv(patient_data,company)
		data={}
    data['first_name'] = patient_data['first_name']
    data['last_name'] = patient_data['last_name']
    data['gender'] = patient_data['gender']
    data['state'] = patient_data['state']
    data['city'] = patient_data['city']
    data['address'] = patient_data['address']
    data['postal_code'] = patient_data['postal_code']
    data['dob'] = patient_data['dob']
		data['notes'] = patient_data['notes']
		data['status'] = patient_data['status']
    data['company_id'] = company
		return data
	end
end
