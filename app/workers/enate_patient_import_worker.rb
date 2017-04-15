class EnatePatientImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: true

  def perform(company,user,business)
    @user = User.find_by(id: user)
    @import_data = JSON.parse(File.read("public/import_files/#{company}/pat-#{@user.first_name}.json"))
		@import_data.each do |import|
      # patient = Patient.find_by(enate_id: import['enateId'])
      # patient.destroy
      patient_data = serialize_patient_data(import,company)
      patient = Patient.find_or_initialize_by(patient_data)
      if patient.save(validate: false)
        save_patient_contact(import,patient)
      end
    end
  end


  def save_patient_contact(import,patient)
    phone_type = ['cell_phone', 'home_phone', 'work_phone']
    phone_type.each do |type|
      unless import["#{type}"].blank?
        contact_no = import["#{type}"].to_s
        mod_num = nil
          only_num = contact_no.gsub(/[^\d]/, '')
          # eleven_digit_num = only_num.slice(0, 11)
          if only_num.size < 10
            more_to_add = (10 - only_num.size)
            txt = ''
            more_to_add.times{txt << 'X'}
            mod_num = '+52'+txt+only_num.to_s
          elsif only_num[0,2] == '52' && only_num.size == 12
            mod_num ='+'+only_num
          elsif only_num[0,3] == '044'
            new_num = only_num.slice(3, 10)
            mod_num = '+52' + new_num
          else
            mod_num = '+52' + only_num
          end


        contact_data = {}
        contact_data['contact_no'] = mod_num
        contact_data['contact_type'] = type.split('_')[0]
        contact_data['patient_id'] = patient.id
        contact = PatientContact.find_or_initialize_by(contact_data)
        contact.save(validate: false)
      end
    end
  end

  def serialize_patient_data(patient_data,company)
    data={}
    data['enate_id'] = patient_data['enateId']
    data['first_name'] = patient_data['firstName']
    data['last_name'] = patient_data['lastName']
    data['gender'] = patient_data['gender']
    data['country'] = patient_data['country']
    data['state'] = patient_data['state']
    data['city'] = patient_data['city']
    data['address'] = patient_data['street']
    data['occupation'] = patient_data['occupation']
    data['postal_code'] = patient_data['postal_code']
    data['emergency_contact'] = patient_data['emergency_contact']
    data['medicare_number'] = patient_data['medicare_number']
    data['age'] = patient_data['age']
    data['dob'] = patient_data['dob']
    data['email'] = patient_data['email']
    data['company_id'] = company
    return data
  end
end
