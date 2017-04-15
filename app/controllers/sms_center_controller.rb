class SmsCenterController < ApplicationController
  include Reminder::ReadyMade
  respond_to :json
  before_filter :authorize, :except => [:sms_receive]
  before_action :find_company_by_sub_domain, :except => [:sms_receive]
  # before_filter :set_rest_api , :only => [:send_sms  , :get_numbers , :buy_number]
  before_filter :stop_activity

  # using only for postman to test API. Remove later
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    result = {}
    render :json => result
  end

  def get_data
    records = []
    page_no = (params[:page].nil? || params[:page].to_i <= 0 ) ? 1 : (params[:page].to_i)
    per_pages = params[:per_page].to_i > 0 ? params[:per_page].to_i : 30
    # next_page = (params['sms_center'][:page].nil? || params['sms_center'][:page].to_i <= 0 ) ? 2 : (params['sms_center'][:page].to_i + 1)
    # prev_page = (params['sms_center'][:page].nil? || params['sms_center'][:page].to_i <= 0 ) ? 0 : (params['sms_center'][:page].to_i - 1)

    if params[:sms_center][:obj_type].present?
      if params[:sms_center][:obj_type].casecmp("patient") == 0
        pagination ,  records = get_patients_listing(params[:sms_center][:filters], params[:sms_center][:filter_type] , page_no , per_pages )

      elsif params[:sms_center][:obj_type].casecmp("user") == 0
        pagination ,  records = get_users_listing(page_no , per_pages)

      elsif params[:sms_center][:obj_type].casecmp("contact") == 0
        pagination ,  records = get_contacts_listing(params[:sms_center][:filters] , page_no , per_pages)

      elsif params[:sms_center][:obj_type].casecmp("birthdays") == 0
        pagination , records = get_birthdays_listing(page_no , per_pages)

      elsif params[:sms_center][:obj_type].casecmp("refers") == 0
        pagination , records = get_refers_listing(page_no , per_pages)

      elsif params[:sms_center][:obj_type].casecmp("recalls") == 0
        pagination , records = get_recalls_listing(page_no , per_pages)
      end
    end
    # Creating listing of objects with their contacts
    result = objects_list_with_their_contacts(records, params[:sms_center][:obj_type])
    render :json => {objects: result , pagination: pagination  , total: pagination[:total].to_i }
  end

  # Getting filters listing

  def filters
    result = {}
    result[:businesses] = []
    result[:doctors] = []
    result[:services] = []

    @company.businesses.each do |bs|
      item = {}
      item[:id] = bs.id
      item[:name] = bs.name
      result[:businesses] << item
    end

    @company.users.doctors.each do |doctor|
      item = {}
      item[:id] = doctor.id
      item[:name] = doctor.full_name_with_title
      result[:doctors] << item
    end

    @company.appointment_types.each do |appnt_type|
      item = {}
      item[:id] = appnt_type.id
      item[:name] = appnt_type.name
      result[:services] << item
    end
    render :json => result
  end

  def send_sms
    if @company.subscription.is_subscribed
      src_no = @company.sms_number.try(:number)
    else
      @company.create_sms_number(number: SMS_TRIAL_NO[:stage]) if @company.sms_number.nil?
      src_no = @company.sms_number.try(:number)
    end
    result = {flag: false}
    unless src_no.nil?
      if params[:sms_center][:receiver].present?
        sms_type = params[:sms_center][:receiver].length > 1 ? SMS_TYPE[0] : SMS_TYPE[1]

        # Getting all unique numbers on which sms has to be delivered
        contact_nos = []
        params["receiver"].map { |rc| contact_nos << rc[:contact] }
        contact_nos = contact_nos.flatten.uniq

        contact_ids = []
        params["receiver"].map { |rc| contact_ids << rc[:id] }
        contact_ids = contact_ids.flatten.uniq

        contact_nos.each_with_index do |mob_no|

          obj_id = nil
          params["receiver"].each do |k|
            obj_id = k["id"] if k["contact"].eql?(mob_no)
          end

          c_code = get_country_code_from_obj(obj_id, params[:sms_center][:obj_type])

          send_status = false
          mob_no_without_c_code = mob_no.phony_formatted(format: :international, spaces: '').phony_normalized
          objs_having_number = get_objects_having_same_number(mob_no_without_c_code, params[:obj_type])

          obj_ids = []
          obj_type = nil
          sm_body = nil
          objs_having_number.each_with_index do |obj, index|
            sms_send_number = @company.sms_setting.default_sms
            if sms_send_number > 0
              accurate_no = mob_no_without_c_code

              # removing extra spaces from html
              coming_sms = params[:sms_center][:msg].split(',').map{|k| k.gsub(/[[:space:]]/ ,' ') }
              coming_sms = coming_sms.map{|k|  (k.blank? || k.empty?) ? coming_sms.delete(k) : k }.join(',')
              half_msg = coming_sms.split('<').map{|k| k.gsub(/[[:space:]]/ ,' ') }.join('<')
              coming_sms = half_msg.split('>').map{|k|  k.gsub(/[[:space:]]/ ,' ') }.join('>')
              (coming_sms = coming_sms + '>') if half_msg.last == '>'
              # here

              body_with_html = make_dynamic_sms_content(coming_sms, obj.id, params[:sms_center][:obj_type], params[:sms_center][:doctor_id], params[:sms_center][:bs_id], params[:sms_center][:contact_id])
              sms_body = Nokogiri::HTML(body_with_html.gsub(/<\/?[^>]+>/, ' ')).text # purpose of nokogiri is to convert html_text into plain text
              patient_id = obj.id if params[:sms_center][:obj_type] == "patient"
              # sending sms one time for all patients having same numbers
              if contact_ids.include?(obj.id)
                plivo_instance = PlivoSms::Sms.new
                response = plivo_instance.send_sms(src_no, accurate_no, sms_body)
                send_status = true if [200, 202].include? response[0]
                obj_type = obj.class.name
                sm_body = sms_body
                sms_send_number = sms_send_number - 1
                @company.sms_setting.update_attributes(:default_sms => sms_send_number)
              end
              obj_ids << obj.id
              result = {flag: true}
            end
          end

          obj_ids.each do |id|
            if send_status
              mob_no = mob_no.phony_formatted(format: :international, spaces: '').phony_normalized
              SmsLog.public_activity_off
              sms_log = @company.sms_logs.create(contact_to: mob_no, contact_from: src_no, sms_type: sms_type, delivered_on: DateTime.now, status: LOG_STATUS[0], sms_text: sm_body, object_id: id, object_type: obj_type , user_id: current_user.id)
              communication = Communication.create(comm_time: Time.now, comm_type: "sms", category: "SMS Message", direction: "sent", to: mob_no, from: src_no, message: sm_body, send_status: true, :patient_id => id)

              receiver_person = sms_log.object # choose any one of them
              SmsLog.public_activity_on
              sms_log.create_activity :create, parameters: sms_log.create_activity_log(current_user, receiver_person, mob_no, sm_body)
              unless cookies[:recall_ids].nil? || cookies[:recall_ids].blank?
                ids = cookies[:recall_ids].split(',')
                ids.each do |recall_id|
                  recall = Recall.find_by_id(recall_id)
                  unless recall.nil?
                    recall.update_column(:is_selected , true)
                  end
                end
                cookies.delete(:recall_ids)
              end
            else
              SmsLog.public_activity_off
              sms_log = @company.sms_logs.create(contact_to: mob_no, contact_from: src_no, sms_type: sms_type, delivered_on: DateTime.now, status: LOG_STATUS[1], sms_text: sm_body, object_id: id, object_type: obj_type, user_id: current_user.id)
              communication = Communication.create(comm_time: Time.now, comm_type: "sms", category: "SMS Message", direction: "sent", to: mob_no, from: src_no, message: sm_body, send_status: false, :patient_id => id)

              receiver_person = sms_log.object # choose any one of them

              SmsLog.public_activity_on
              sms_log.create_activity :failed, parameters: sms_log.create_activity_log(current_user, receiver_person, mob_no, sm_body)
              cookies.delete(:recall_ids)
            end

          end
        end
      end
      if result[:flag] == true
        render :json => result
      else
        if @company.sms_setting.default_sms <=0
          comm = Communication.new
          comm.errors.add('', 'SMS credits balance is low !')
          show_error_json(comm.errors.messages)
        else
          comm = Communication.new
          comm.errors.add(:destination, "Number not found")
          show_error_json(comm.errors.messages)
        end

      end
    else
      result = {flag: false, :error => "please purchase a number !"}
      render :json => result
    end
  end

  def sms_receive
    formatted_number = PhonyRails.normalize_number(params[:To])
    sms_num = SmsNumber.find_by(number: formatted_number)
    unless sms_num.nil?
      company = sms_num.company
      # company = Company.find(76)
      if company.subscription.try(:is_subscribed) == true
        contact_to = PhonyRails.normalize_number(params[:To])
        contact_from = PhonyRails.normalize_number(params[:From])
        sms_text = params[:Text]
        no_exist = false

        # forword the patient reply to sms setting mentioned mob number and email
        forward_patient_reply_sms_setting_no(company , contact_from , sms_text)
        forward_patient_reply_sms_setting_email(company , contact_from , sms_text)

        # Getting all patients having same mob number
        patients_having_number = company.patients.active_patient.joins(:patient_contacts).where("contact_no = ?", contact_from)
        patients_having_number.each do |patient|
          no_exist = true
          SmsLog.public_activity_off
          sms_log = company.sms_logs.create(contact_to: contact_to, contact_from: contact_from, sms_type: SMS_TYPE[1], delivered_on: DateTime.now, status: LOG_STATUS[2], patient_id: patient.id, sms_text: sms_text, object_id: patient.id, object_type: patient.class.name)
          SmsLog.public_activity_on
          sms_log.create_activity :receive, parameters: sms_log.receive_activity_log(patient, sms_text, contact_from, "Patient")
        end


        # Getting all contacts having same mob number
        contacts_having_number = company.contacts.active_contact.joins(:contact_nos).where("contact_number = ?", contact_from)
        contacts_having_number.each do |contact|
          SmsLog.public_activity_off
          sms_log = company.sms_logs.create(contact_to: contact_to, contact_from: contact_from, sms_type: SMS_TYPE[1], delivered_on: DateTime.now, status: LOG_STATUS[2], contact_id: contact.id, sms_text: sms_text, object_id: contact.id, object_type: contact.class.name)
          SmsLog.public_activity_on
          sms_log.create_activity :receive, parameters: sms_log.receive_activity_log(contact, sms_text, contact_from, "Contact")
          no_exist = true
        end

        # Getting all users and practitioners having same mob number
        users_having_number = company.users.where("phone = ?", contact_from)
        users_having_number.each do |user|
          SmsLog.public_activity_off
          sms_log = company.sms_logs.create(contact_to: contact_to, contact_from: contact_from, sms_type: SMS_TYPE[1], delivered_on: DateTime.now, status: LOG_STATUS[2], user_id: user.id, sms_text: sms_text, object_id: user.id, object_type: user.class.name)
          SmsLog.public_activity_on
          sms_log.create_activity :receive, parameters: sms_log.receive_activity_log(user, sms_text, contact_from, "User")
          no_exist = true
        end
        unless no_exist
          SmsLog.public_activity_off
          sms_log = company.sms_logs.create(contact_to: contact_to, contact_from: contact_from, sms_type: SMS_TYPE[1], delivered_on: DateTime.now, status: LOG_STATUS[2], sms_text: sms_text)
          SmsLog.public_activity_on
          sms_log.create_activity :receive, parameters: sms_log.receive_activity_log(nil, sms_text, contact_from)
        end
      end
    end
    render :json => {flag: true}

  end

  # Fetch all logs

  def get_logs
    result = []
    start_date = params[:start_date].to_date unless params[:start_date].nil?
    end_date = params[:end_date].to_date unless params[:end_date].nil?
    user_id = params[:user_id].nil? ? nil : params[:user_id].to_i
    per_pages = params[:per_page].to_i > 0 ? params[:per_page].to_i : 30

    smslogs = get_sms_logs(start_date , end_date , user_id , per_pages)



    smslogs.each do |log|
      item = {}
      item["to"] = log.contact_to.phony_formatted(format: :international, spaces: '-')
      item["from"] = log.contact_from
      item["sms_type"] = log.sms_type
      item["delivered_on"] = log.delivered_on
      item["status"] = log.status
      sender_name = log.get_sender.try(:full_name)
      item["sender_id"] = log.get_sender.try(:id)
      item["sender_name"] = sender_name.nil? ? "Unknown" : sender_name
      item["concession"] = log.find_concession_type_for_log
      item["sender_type"] = log.get_sender.try(:class).to_s
      item[:current_user_msg_sender] = log.user.try(:full_name_with_title)
      result << item
    end
    avail_users = @company.users.where(acc_active: true).select('id , title , first_name , last_name')
    all_users = []
    avail_users.each do |usr|
      item = {}
      item[:id] = usr.id
      item[:full_name] = usr.full_name_with_title
      all_users << item
    end
    render :json => {total: smslogs.count ,  logs: result , all_users: all_users }
  end

  def download_logs
    begin
      start_date = params[:start_date].to_date unless params[:start_date].nil?
      end_date = params[:end_date].to_date unless params[:end_date].nil?
      user_id = params[:user_id].nil? ? nil : params[:user_id].to_i
      per_pages = params[:per_page].to_i > 0 ? params[:per_page].to_i : 30

      @smslogs = get_sms_logs(start_date , end_date , user_id , per_pages)

      respond_to do |format|
        format.html
        format.csv { render text: @smslogs.to_csv , status: 200 }
      end

    rescue Exception => e
      render :text => e.message
    end

  end

  def get_objects_with_phone_nos
    unless params[:recall_ids].blank? || params[:recall_ids].nil?
      if params[:recall_ids].split(',').length == 0
        cookies.delete('recall_ids')
      else
        cookies[:recall_ids] = params[:recall_ids]
      end
    else
      cookies.delete('recall_ids')
    end
    result = {}
    result[:obj_type] = params[:obj_type]
    obj_ids = params["ids"].nil? ? nil : params["ids"].split(",").map { |a| a.to_i }

    result[:selected_obj_list] = get_objects_with_nos(obj_ids, params[:obj_type] , true , params['filterDate'] )
    result[:avail_obj_list] = get_objects_with_nos(obj_ids, params[:obj_type], false , params['filterDate'] )
    render :json => result
  end

  # Getting list of available numbers for sms only  sms_enabled = true

  def get_numbers
    country_iso = @company.account.country
    plivo_instance = PlivoSms::Sms.new
    # Getting Plivo available numbers
    numbers = plivo_instance.get_numbers(country_iso)
    result = []
    objects = numbers[1]["objects"]
    objects.each do |obj|
      if obj["sms_enabled"] == true
        item = {}
        item[:country] = obj["country"]
        item[:number] = obj["number"]
        item[:region] = obj["region"]
        item[:sms_enabled] = obj["sms_enabled"]
        item[:type] = obj["type"]
        item[:monthly_rental_rate] = obj["monthly_rental_rate"]
        result << item
      end

    end
    render :json => result
  end

  # buy a number

  def buy_number
    result = {}
    plivo_instance = PlivoSms::Sms.new

    # Purchase a plivo number
    response = plivo_instance.buy_number(params[:number])

    if response[1]["numbers"].present?
      @company.create_sms_number(number: params[:number]) # Creating sms number for a company
      result = {flag: true, number: "purchased"}
    else
      result = {flag: false, number: "has been sold."}
    end
    render :json => result
  end

  # Getting all chats of unknown number
  def chat_history_of_unknown_no
    result = {}
    unless params[:unknown_no].nil?
      normalized_no = PhonyRails.normalize_number(params[:unknown_no])
      msg = @company.sms_logs.where(contact_from: normalized_no).select('sms_text ,delivered_on , status  ')
      result[:number] = normalized_no unless msg.empty?
      result[:conversation] = []
      msg.each do |msg_obj|
        item = {}
        item[:sms_body] = msg_obj.sms_text
        item[:sent_time] = msg_obj.delivered_on.strftime("%d-%m-%Y at %H:%M%p")
        item[:status] = msg_obj.status
        item[:direction] = 'inbound'
        result[:conversation] << item
      end
    end
    render :json => result
  end

  private

  def find_object_as_per_contact(contact_from)
    patient = PatientContact.find_by_contact_no(contact_from).try(:patient)
    return patient unless patient.nil?

    contact = ContactNo.find_by_contact_number(contact_from).try(:contact)
    return contact unless contact.nil?
  end


  def get_patients_listing(filter_params, filter_type ,page_no , per_pages)
    result = []
    pagination = {}
    if filter_type.casecmp("appnt") == 0
      start_date = filter_params[:st_date].to_date unless filter_params[:st_date].nil?
      end_date = filter_params[:end_date].to_date unless filter_params[:end_date].nil?

      loc_params = filter_params["bs_id"].blank? ? nil : filter_params["bs_id"].split(",").map { |a| a.to_i }
      doctor_params = filter_params["doctor"].blank? ? nil : filter_params["doctor"].split(",").map { |a| a.to_i }
      service_params = filter_params["service"].blank? ? nil : filter_params["service"].split(",").map { |a| a.to_i }
      upcoming_status = filter_params["upcoming"]

      pagination , result = get_patients(start_date, end_date, loc_params, doctor_params, service_params, upcoming_status , page_no , per_pages)
    else
      outstanding = filter_params[:outstanding]
      credit = filter_params[:credit]
      pagination , result = get_patients_payment_wise(outstanding, credit , page_no , per_pages)

    end
    # result = @company.patients.active_patient
    return pagination , result
  end

  def get_users_listing(page_no , per_pages)
    users = @company.users.where(['acc_active= ? AND (phone IS NOT ? AND phone != ?) ', true , nil , '' ]).uniq.paginate(:per_page=> per_pages , page: page_no)
    pagination = get_pagination_detail( per_pages , page_no , users.uniq.count)
    return pagination  , users
  end

  def get_contacts_listing(filter_params , page_no , per_pages)
    standard = filter_params[:standard]
    doctor = filter_params[:doctor]
    third_party = filter_params[:third_party]
    if standard == false && doctor == false && third_party == false
      contacts = @company.contacts.active_contact.paginate(page: page_no, per_page: per_pages)
    elsif standard == true && doctor == false && third_party == false
      contacts = @company.contacts.active_contact.joins(:contact_nos).where(["contact_nos.contact_number IS NOT ? AND contacts.contact_type IN (?)", nil ,  ["standard", "Standard"]]).paginate(page: page_no, per_page: per_pages)
    elsif standard == false && doctor == true && third_party == false
      contacts = @company.contacts.active_contact.joins(:contact_nos).where(["contact_nos.contact_number IS NOT ? AND contacts.contact_type IN (?)", nil , ["doctor", "Doctor"]]).paginate(page: page_no, per_page: per_pages)
    elsif standard == false && doctor == false && third_party == true
      contacts = @company.contacts.active_contact.joins(:contact_nos).where(["contact_nos.contact_number IS NOT ? AND contacts.contact_type IN (?)", nil ,["3rd Party Payer", "3rd party Payer"]]).paginate(page: page_no, per_page: per_pages)
    elsif standard == true && doctor == true && third_party == false
      contacts = @company.contacts.active_contact.joins(:contact_nos).where(["contact_nos.contact_number IS NOT ? AND contacts.contact_type IN (?)", nil ,  ["standard", "Standard", "doctor", "Doctor"]]).paginate(page: page_no, per_page: per_pages)
    elsif standard == true && doctor == false && third_party == true
      contacts = @company.contacts.active_contact.joins(:contact_nos).where(["contact_nos.contact_number IS NOT ? AND contacts.contact_type IN (?)", nil ,  ["3rd Party Payer", "3rd party Payer", "standard", "Standard"]]).paginate(page: page_no, per_page: per_pages)
    elsif standard == false && doctor == true && third_party == true
      contacts = @company.contacts.active_contact.joins(:contact_nos).where(["contact_nos.contact_number IS NOT ? AND contacts.contact_type IN (?)", nil ,["3rd Party Payer", "3rd party Payer", "doctor", "Doctor"]]).paginate(page: page_no, per_page: per_pages)
    elsif standard == true && doctor == true && third_party == true
      contacts = @company.contacts.active_contact.joins(:contact_nos).where(["contact_nos.contact_number IS NOT ? AND contacts.contact_type IN (?)", nil ,  ["3rd Party Payer", "3rd party Payer", "doctor", "Doctor", "standard", "Standard"]]).paginate(page: page_no, per_page: per_pages)
    end
    pagination = get_pagination_detail(per_pages , page_no , contacts.uniq.count)
    return pagination , contacts.uniq
  end

  def get_birthdays_listing(page_no  , per_pages)
    result = @company.patients.active_patient.joins(:patient_contacts ).where(['patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND Month(patients.dob) = ? AND Day(patients.dob) = ? ', nil ,  false ,params[:filterDate].to_date.strftime("%m"),  params[:filterDate].to_date.strftime("%d")]).uniq.paginate(page: page_no , per_page: per_pages)
    pagination = get_pagination_detail( per_pages , page_no , result.count)
    return pagination , result
  end

  def get_refers_listing(page_no , per_pages)
    referrers = @company.patients.active_patient.where(['referrer IS NOT ? AND DATE(patients.created_at) = ?' , nil, params[:filterDate].to_date]).select("id , referrer , referral_id , referral_type")
    referrer_ids = []
    referrers.each { |k| referrer_ids << k['id'] }
    #referrer_patient =
    refer_patients_ids = referrer_ids.compact.uniq
    refer_patients = Patient.active_patient.joins(:patient_contacts).where(['patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND patients.id IN (?) ', nil , false ,refer_patients_ids]).paginate(page: page_no , per_page: per_pages)
    pagination = get_pagination_detail(per_pages , page_no , refer_patients.uniq.count)
    return pagination , refer_patients.uniq
  end

  def get_recalls_listing(page_no , per_pages)
    result = @company.recalls.joins(:patient => [:patient_contacts] ).where('patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND Date(recalls.recall_on_date) = ?', nil , false , params[:filterDate].to_date).uniq.paginate(page: page_no , per_page: per_pages)
    pagination = get_pagination_detail(per_pages , page_no , result.count)
    return pagination , result
  end
  # Method to get listing of objects with their contacts numbers
  def objects_list_with_their_contacts(records, obj_type )
    result = []
    if obj_type.casecmp("patient") == 0
      records.each do |obj|
        item = {}
        item[:id] = obj.id
        item[:name] = obj.full_name
        item[:concession] = obj.concession.try(:name)
        item[:contact_one] = obj.get_contacts(0)
        item[:contact_second] = obj.get_contacts(1)
        item[:contact_third] = obj.get_contacts(2)
        item[:contact_fourth] = obj.get_contacts(3)
        result << item
      end
    elsif obj_type.casecmp("user") == 0
      records.each do |obj|
        item = {}
        item[:id] = obj.id
        item[:name] = obj.full_name_with_title
        item[:contact_one] = obj.phone
        item[:contact_second] = nil
        item[:contact_third] = nil
        item[:contact_fourth] = nil
        result << item
      end

    elsif obj_type.casecmp("contact") == 0
      records.each do |obj|
        item = {}
        item[:id] = obj.id
        item[:name] = obj.full_name
        item[:contact_one] = obj.get_contacts(0)
        item[:contact_second] = obj.get_contacts(1)
        item[:contact_third] = obj.get_contacts(2)
        item[:contact_fourth] = obj.get_contacts(3)
        result << item
      end

    elsif obj_type.casecmp("birthdays") == 0
      records.each do |obj|
        item = {}
        item[:id] = obj.id
        item[:name] = obj.full_name
        item[:concession] = obj.concession.try(:name)
        item[:contact_one] = obj.get_contacts(0)
        item[:contact_second] = obj.get_contacts(1)
        item[:contact_third] = obj.get_contacts(2)
        item[:contact_fourth] = obj.get_contacts(3)
        result << item
      end

    elsif obj_type.casecmp("refers") == 0
      records.each do |obj|
        item = {}
        item[:id] = obj.id
        item[:name] = obj.full_name
        item[:contact_one] = obj.get_contacts(0)
        item[:contact_second] = nil
        item[:contact_third] = nil
        item[:contact_fourth] = nil
        result << item
      end

    elsif obj_type.casecmp("recalls") == 0
      records.each do |obj|
        item = {}
        item[:id] = obj.patient.try(:id)
        item[:name] = obj.patient.try(:full_name)
        item[:contact_one] = obj.patient.get_primary_contact
        item[:contact_second] = nil
        item[:contact_third] = nil
        item[:contact_fourth] = nil
        item[:recall_type] = obj.recall_type.try(:name)
        item[:is_recall_complete] = obj.is_selected
        item[:recall_id] = obj.try(:id)
        result << item
      end
    end

    return result
  end

  # Getting patient for appnt filter
  def get_patients(start_date, end_date, loc_params, doctor_params, service_params, upcoming = false ,page_no , per_pages)
    patients = []
    pagination = {}
    if loc_params.nil? && doctor_params.nil? && service_params.nil?
      if start_date.nil? && end_date.nil?
        patients = @company.patients.active_patient.joins(:patient_contacts).where(['contact_no IS NOT ? AND sms_marketing = ?', nil , false]).paginate(:page => page_no , :per_page=> per_pages)
      else
        patients = @company.patients.active_patient.joins(:appointments , :patient_contacts).where([" contact_no IS NOT ? AND patients.sms_marketing = ? AND DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ? AND appointments.status = ?", nil , false , start_date, end_date, true]).paginate(:page => page_no , :per_page=> per_pages)
      end

    elsif !(loc_params.nil?) && doctor_params.nil? && service_params.nil?
      if start_date.nil? && end_date.nil?
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:business]).where(["contact_no IS NOT ? AND patients.sms_marketing= ? AND appointments.status = ? AND businesses.id IN (?)", nil , false , true, loc_params]).paginate(:page => page_no , :per_page=> per_pages)
      else
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:business]).where(["contact_no IS NOT ? AND patients.sms_marketing =? AND appointments.status = ? AND businesses.id IN (?) ", nil , false ,true, loc_params]).where(["DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ?", start_date, end_date]).paginate(:page => page_no , :per_page=> per_pages)
      end
    elsif loc_params.nil? && !(doctor_params.nil?) && (service_params.nil?)
      if start_date.nil? && end_date.nil?
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:user]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND users.id IN (?)", nil , false , true, doctor_params]).paginate(:page => page_no , :per_page=> per_pages)
      else
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:user]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND users.id IN (?)", nil ,  false , true, doctor_params]).where(["DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ?", start_date, end_date]).paginate(:page => page_no , :per_page=> per_pages)
      end
    elsif loc_params.nil? && (doctor_params.nil?) && !(service_params.nil?)
      if start_date.nil? && end_date.nil?
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:appointment_type]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND appointment_types.id IN (?)", nil , false , true, service_params]).paginate(:page => page_no , :per_page=> per_pages)
      else
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:appointment_type]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND appointment_types.id IN (?)", nil , false , true, service_params]).where(["DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ?", start_date, end_date]).paginate(:page => page_no , :per_page=> per_pages)
      end
    elsif !(loc_params.nil?) && !(doctor_params.nil?) && (service_params.nil?)
      if start_date.nil? && end_date.nil?
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:business, :user]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND users.id IN (?) AND businesses.id IN (?) ", nil ,  false , true, doctor_params, loc_params]).paginate(:page => page_no , :per_page=> per_pages)
      else
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:business, :user]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND users.id IN (?) AND businesses.id IN (?) ", nil ,false , true, doctor_params, loc_params]).where(["DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ?", start_date, end_date]).paginate(:page => page_no , :per_page=> per_pages)
      end
    elsif !(loc_params.nil?) && (doctor_params.nil?) && !(service_params.nil?)
      if start_date.nil? && end_date.nil?
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:business, :appointment_type]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND  appointments.status = ? AND appointment_types.id IN (?) AND businesses.id IN (?) ", nil , false ,true, service_params, loc_params]).paginate(:page => page_no , :per_page=> per_pages)
      else
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:business, :appointment_type]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND appointment_types.id IN (?) AND businesses.id IN (?) ", nil , false ,true, service_params, loc_params]).where(["DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ?", start_date, end_date]).paginate(:page => page_no , :per_page=> per_pages)
      end
    elsif (loc_params.nil?) && !(doctor_params.nil?) && !(service_params.nil?)
      if start_date.nil? && end_date.nil?
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointment => [:user, :appointment_type]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND users.id IN (?) AND appointment_types.id IN (?)", nil ,  false , true ,  doctor_params, service_params]).paginate(:page => page_no , :per_page=> per_pages)
      else
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointment => [:user, :appointment_type]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND users.id IN (?) AND appointment_types.id IN (?)", nil ,  false , true , doctor_params, service_params]).where(["DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ?", start_date, end_date]).paginate(:page => page_no , :per_page=> per_pages)
      end
    elsif !(loc_params.nil?) && !(doctor_params.nil?) && !(service_params.nil?)
      if start_date.nil? && end_date.nil?
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:business, :user, :appointment_type]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND appointments.status = ? AND appointment_types.id IN (?) AND businesses.id IN (?) AND users.id IN (?) ", nil , false , true, service_params, loc_params, doctor_params]).paginate(:page => page_no , :per_page=> per_pages)
      else
        patients = @company.patients.active_patient.joins(:patient_contacts , :appointments => [:business, :user, :appointment_type]).where(["contact_no IS NOT ? AND patients.sms_marketing = ? AND  appointments.status = ? AND appointment_types.id IN (?) AND businesses.id IN (?) AND users.id IN (?) ", nil ,false , true, service_params, loc_params, doctor_params]).where(["DATE(appointments.appnt_date) >= ? AND DATE(appointments.appnt_date) <= ?", start_date, end_date]).paginate(:page => page_no , :per_page=> per_pages)
      end
    end

    if upcoming
      patients = patients.joins(:appointments).where(["patients.sms_marketing = ? AND (Date(appointments.appnt_date) < ?  AND appointments.status= ?) || (Date(appointments.appnt_date) <= ? AND appointments.appnt_time_start  < CAST(?  AS time) AND appointments.status= ?)", false ,  DateTime.now, true, DateTime.now, DateTime.now, true]).uniq.paginate(:page => page_no , :per_page=> per_pages)
    end
    pagination = get_pagination_detail(Patient.per_page  , page_no , patients.uniq.count)
    return pagination , patients.uniq
  end

  # Getting Patient for payment filter
  def get_patients_payment_wise(outstanding, credit , page_no ,  per_pages)
    patients = []
    patients = @company.patients.active_patient
    patients_ids = []
    if (outstanding == true) && (credit == false)
      patients.each do |patient|
        patients_ids << patient.id if patient.calculate_patient_outstanding_balance > 0
      end


    elsif (outstanding == false) && (credit == true)
      patients.each do |patient|
        patients_ids << patient.id if patient.calculate_patient_credit_amount > 0
      end
      # patients = []
      # patients = @company.patients.active_patient.where(["patients.id IN (?)", patients_ids])

    elsif (outstanding == true) && (credit == true)
      patients.each do |patient|
        patients_ids << patient.id if patient.calculate_patient_credit_amount > 0 || patient.calculate_patient_outstanding_balance > 0
      end
      # patients = []
      # patients = @company.patients.active_patient.where(["patients.id IN (?)", patients_ids])
    end

    patients = @company.patients.active_patient.where(["patients.id IN (?)", patients_ids]).paginate(:page => page_no , per_page: per_pages)
    pagination = get_pagination_detail(Patient.per_page  , page_no , patients.count)
    return pagination ,  patients
  end

  def get_objects_with_nos(obj_ids, obj_type, selected = true , flt_date )
    objects = []
    result = []
    filter_date = flt_date.to_date unless flt_date.nil?
    if obj_type == "patient"
      if selected == true
        objects = @company.patients.active_patient.where(["patients.id IN (?)", obj_ids])
      else
        objects = @company.patients.active_patient
      end

    elsif obj_type == "user"
      if selected == true
        objects = @company.users.where(["users.id IN (?) AND users.acc_active = ? ", obj_ids, true])
      else
        objects = @company.users.where(["users.acc_active = ? ", true])
      end

    elsif obj_type == "contact"
      if selected == true
        objects = @company.contacts.active_contact.where(["contacts.id IN (?)", obj_ids])
      else
        objects = @company.contacts.active_contact
      end
    elsif obj_type == "recalls"
      recall_ids = params["recall_ids"].nil? ? nil : params["recall_ids"].split(",").map { |a| a.to_i }
      if selected == true
        objects = @company.recalls.joins(:patient => [:patient_contacts] ).where('recalls.id IN (?) AND patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND Date(recalls.recall_on_date) = ?' , recall_ids , nil , false , filter_date).uniq
      else
        objects = @company.recalls.joins(:patient => [:patient_contacts] ).where('recalls.id NOT IN (?) AND patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND Date(recalls.recall_on_date) = ?', recall_ids , nil , false , filter_date).uniq
      end
    elsif obj_type.casecmp("birthdays") == 0
      if selected == true
        objects = @company.patients.active_patient.joins(:patient_contacts ).where(['patients.id IN (?) AND patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND Month(patients.dob) = ? AND Day(patients.dob) = ? ' , obj_ids, nil ,  false , filter_date.strftime("%m"),  filter_date.strftime("%d")]).uniq
      else
        objects = @company.patients.active_patient.joins(:patient_contacts ).where(['patients.id NOT IN (?) AND patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND Month(patients.dob) = ? AND Day(patients.dob) = ? ' , obj_ids, nil ,  false , filter_date.strftime("%m"),  filter_date.strftime("%d")]).uniq
      end

    elsif obj_type.casecmp("refers") == 0
      referrers = @company.patients.active_patient.where(['referrer IS NOT ? AND DATE(patients.created_at) = ?' , nil, filter_date ]).select("id , referrer , referral_id , referral_type")
      referrer_ids = []
      referrers.each { |k| referrer_ids << k['id'] }
      refer_patients_ids = referrer_ids.compact.uniq
      if selected == true
        objects = Patient.active_patient.joins(:patient_contacts).where(['patients.id IN (?) AND patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND patients.id IN (?) ' , obj_ids , nil , false ,refer_patients_ids])
      else
        objects = Patient.active_patient.joins(:patient_contacts).where(['patients.id NOT IN (?) AND patient_contacts.contact_no IS NOT ? AND patients.sms_marketing = ? AND patients.id IN (?) ' , obj_ids , nil , false ,refer_patients_ids])
      end
    end

    objects.each do |obj|
      obj = obj.patient if obj_type == "recalls"
      unless obj.get_primary_contact.nil?
        item = {}
        item[:id] = obj.id
        item[:name] = obj.full_name
        item[:contact] = obj.get_primary_contact
        result << item
      end
    end
    return result
  end

  def get_objects_having_same_number(mob_no, obj_type)
    objects = []
    if %w(patient recalls refers birthdays).include?(obj_type)
      objects = @company.patients.active_patient.joins(:patient_contacts).where(["patient_contacts.contact_no = ?", "#{mob_no}"])
    elsif obj_type.casecmp("contact") == 0
      objects = @company.contacts.active_contact.joins(:contact_nos).where(["contact_nos.contact_number = ?", "#{mob_no}"])
    elsif obj_type.casecmp("user") == 0
      objects = @company.users.where(["acc_active = ? AND phone =? ", true, mob_no])
    end
    return objects
  end

  def get_accurate_no(obj_id, contact_no, obj_type)
    if obj_type == "patient"
      patient = Patient.find_by_id(obj_id)
      unless patient.nil?
        country_sym = patient.country
        country = ISO3166::Country.new(country_sym)
        unless country.nil?
          contact_no = "#{country.country_code}#{contact_no}" unless contact_no.starts_with?(country.country_code)
        end
      end

    elsif obj_type == "contact"
      contact = Contact.find_by_id(obj_id)
      unless contact.nil?
        country_sym = contact.country
        country = ISO3166::Country.new(country_sym)
        unless country.nil?
          contact_no = "#{country.country_code}#{contact_no}" unless contact_no.starts_with?(country.country_code)
        end
      end
    end
    return contact_no
  end

  def make_dynamic_sms_content(content, receiver_id, obj_type, doctor_id=nil, bs_id=nil, contact_id=nil)
    patient = Patient.find_by_id(receiver_id) unless receiver_id.nil?
    doctor = SmsLog.doctor(doctor_id) unless doctor_id.nil?
    contact = Contact.find_by_id(contact_id) unless contact_id.nil?
    loc = Business.find_by_id(bs_id) unless bs_id.nil?

    refer_doc = patient.try(:contact)

    replace_data = matcher_var(patient, doctor, loc, contact, refer_doc)
    matcher = /#{replace_data.keys.join('|')}/
    content = content.gsub(matcher, replace_data)
    return content

  end


  def matcher_var(patient=nil, practitioner=nil, business=nil, contact=nil, refer_doc=nil)
    str = {}
    #      key value for patient tab
    unless patient.nil?
      pt_tab = PatientTab.first
      str["{{#{pt_tab.full_name}}}"] = "#{patient.full_name}" rescue nil
      str["{{#{pt_tab.title}}}"] = "#{patient.title}" rescue nil
      str["{{#{pt_tab.first_name}}}"] = "#{patient.first_name}" rescue nil
      str["{{#{pt_tab.last_name}}}"] = "#{patient.last_name}" rescue nil
      str["{{#{pt_tab.mobile_number}}}"] = "#{patient.get_mobile_no_type_wise("mobile")}" rescue nil
      str["{{#{pt_tab.home_number}}}"] = "#{patient.get_mobile_no_type_wise("home")}" rescue nil
      str["{{#{pt_tab.work_number}}}"] = "#{patient.get_mobile_no_type_wise("work")}" rescue nil
      str["{{#{pt_tab.fax_number}}}"] = "#{patient.get_mobile_no_type_wise("fax")}" rescue nil
      str["{{#{pt_tab.other_number}}}"] = "#{patient.get_mobile_no_type_wise("other")}" rescue nil
      str["{{#{pt_tab.email}}}"] = "#{patient.email}" rescue nil
      str["{{#{pt_tab.dob}}}"] = "#{patient.dob}" rescue nil
      str["{{#{pt_tab.address}}}"] = "#{patient.address}" rescue nil
      str["{{#{pt_tab.city}}}"] = "#{patient.city}" rescue nil
      str["{{#{pt_tab.post_code}}}"] = "#{patient.postal_code}" rescue nil
      state , country = patient.get_state_country_name
      str["{{#{pt_tab.state}}}"] = "#{state}" rescue nil
      str["{{#{pt_tab.country}}}"] = "#{country}" rescue nil
      str["{{#{pt_tab.gender}}}"] = "#{patient.gender}" rescue nil
      str["{{#{pt_tab.occupation}}}"] = "#{patient.occupation}" rescue nil
      str["{{#{pt_tab.emergency_contact}}}"] = "#{patient.emergency_contact}" rescue nil
      str["{{#{pt_tab.referral_source}}}"] = "#{patient.get_referral_source}" rescue nil
      str["{{#{pt_tab.medicare_number}}}"] = "#{patient.medicare_number}" rescue nil
      str["{{#{pt_tab.old_reference_id}}}"] = "#{patient.identification_key}" rescue nil
      str["{{#{pt_tab.id_number}}}"] = "#{patient.id}" rescue nil
      str["{{#{pt_tab.notes}}}"] = "#{patient.notes}" rescue nil
      str["{{#{pt_tab.first_appt_date}}}"] = "#{patient.get_first_appt_date}"  rescue nil
      str["{{#{pt_tab.first_appt_time}}}"] = "#{patient.get_first_appt_time}"  rescue nil
      str["{{#{pt_tab.most_recent_appt_date}}}"] = "#{patient.get_most_recent_appt_date}" rescue nil
      str["{{#{pt_tab.most_recent_appt_time}}}"] = "#{patient.get_most_recent_appt_time}" rescue nil
      str["{{#{pt_tab.next_appt_date}}}"] = "#{patient.get_next_appt_date}" rescue nil
      str["{{#{pt_tab.next_appt_time}}}"] = "#{patient.get_next_appt_time}" rescue nil
    end
    # key value for practitoner  tab
    unless practitioner.nil?
      pract_tab = PractitionerTab.first
      str["{{#{pract_tab.full_name}}}"] = "#{practitioner.full_name}" rescue nil
      str["{{#{pract_tab.full_name_with_title}}}"] = "#{practitioner.full_name_with_title}" rescue nil
      str["{{#{pract_tab.title}}}"] = "#{practitioner.title}" rescue nil
      str["{{#{pract_tab.first_name}}}"] = "#{practitioner.first_name}" rescue nil
      str["{{#{pract_tab.last_name}}}"] = "#{practitioner.last_name}" rescue nil
      str["{{#{pract_tab.designation}}}"] = "#{practitioner.try(:practi_info).try(:designation)}" rescue nil
      str["{{#{pract_tab.email}}}"] = "#{practitioner.email}" rescue nil
      str["{{#{pract_tab.mobile_number}}}"] = "#{practitioner.phone}" rescue nil
    end
    #  key value for business tab
    unless business.nil?
      bs_tab = BusinessTab.first
      str["{{#{bs_tab.name}}}"] = "#{business.name}" rescue nil
      str["{{#{bs_tab.full_address}}}"] = "#{business.full_address}" rescue nil
      str["{{#{bs_tab.address}}}"] = "#{business.address}" rescue nil
      str["{{#{bs_tab.city}}}"] = "#{business.city}" rescue nil
      state , country = business.get_state_country_name rescue nil
      str["{{#{bs_tab.state}}}"] = "#{state}" rescue nil
      str["{{#{bs_tab.post_code}}}"] = "#{business.pin_code}" rescue nil
      str["{{#{bs_tab.country}}}"] = "#{country}" rescue nil
      str["{{#{bs_tab.registration_name}}}"] = "#{business.reg_name}" rescue nil
      str["{{#{bs_tab.registration_value}}}"] = "#{business.reg_number}" rescue nil
      str["{{#{bs_tab.website_address}}}"] = "#{business.web_url}" rescue nil
      str["{{#{bs_tab.ContactInformation}}}"] = "#{business.contact_info}" rescue nil
    end
    # key value for contact tab
    unless contact.nil?
      cont_tab = ContactTab.first
      str["{{#{cont_tab.full_name}}}"] = "#{contact.full_name}"  rescue nil
      str["{{#{cont_tab.title}}}"] = "#{contact.title}" rescue nil
      str["{{#{cont_tab.first_name}}}"] = "#{contact.first_name}" rescue nil
      str["{{#{cont_tab.last_name}}}"] = "#{contact.last_name}" rescue nil
      str["{{#{cont_tab.preferred_name}}}"] = "#{contact.preffered_name}" rescue nil
      str["{{#{cont_tab.company_name}}}"] = "#{contact.company_name}" rescue nil
      str["{{#{cont_tab.mobile_number}}}"] = "#{contact.get_mobile_no_type_wise("mobile")}" rescue nil
      str["{{#{cont_tab.home_number}}}"] = "#{contact.get_mobile_no_type_wise("home")}" rescue nil
      str["{{#{cont_tab.work_number}}}"] = "#{contact.get_mobile_no_type_wise("work")}" rescue nil
      str["{{#{cont_tab.fax_number}}}"] = "#{contact.get_mobile_no_type_wise("fax")}" rescue nil
      str["{{#{cont_tab.other_number}}}"] = "#{contact.get_mobile_no_type_wise("other")}" rescue nil
      str["{{#{cont_tab.email}}}"] = "#{contact.email}" rescue nil
      str["{{#{cont_tab.address}}}"] = "#{contact.address}" rescue nil
      str["{{#{cont_tab.city}}}"] = "#{contact.city}" rescue nil
      state , country = contact.get_state_country_name rescue nil
      str["{{#{cont_tab.state}}}"] = "#{state}" rescue nil
      str["{{#{cont_tab.post_code}}}"] = "#{contact.post_code}" rescue nil
      str["{{#{cont_tab.country}}}"] = "#{country}" rescue nil
      str["{{#{cont_tab.occupation}}}"] = "#{contact.occupation}" rescue nil
      str["{{#{cont_tab.notes}}}"] = "#{contact.notes}" rescue nil
      str["{{#{cont_tab.provider_number}}}"] = "#{contact.provider_number}" rescue nil
    end
    # key value for refer doc tab
    unless refer_doc.nil?
      refer_doc_tab = ReferringDoctorTab.first

      str["{{#{refer_doc_tab.full_name}}}"] = "#{refer_doc.full_name}" rescue nil
      str["{{#{refer_doc_tab.title}}}"] = "#{refer_doc.title}" rescue nil
      str["{{#{refer_doc_tab.first_name}}}"] = "#{refer_doc.first_name}" rescue nil
      str["{{#{refer_doc_tab.last_name}}}"] = "#{refer_doc.last_name}" rescue nil
      str["{{#{refer_doc_tab.email}}}"] = "#{refer_doc.email}" rescue nil
      str["{{#{refer_doc_tab.mobile_number}}}"] = "#{refer_doc.get_mobile_no_type_wise("mobile")}" rescue nil
      str["{{#{refer_doc_tab.home_number}}}"] = "#{refer_doc.get_mobile_no_type_wise("home")}" rescue nil
      str["{{#{refer_doc_tab.work_number}}}"] = "#{refer_doc.get_mobile_no_type_wise("work")}" rescue nil
      str["{{#{refer_doc_tab.fax_number}}}"] = "#{refer_doc.get_mobile_no_type_wise("fax")}" rescue nil
      str["{{#{refer_doc_tab.other_number}}}"] = "#{refer_doc.get_mobile_no_type_wise("other")}" rescue nil


      str["{{#{refer_doc_tab.preferred_name}}}"] = "#{refer_doc.preffered_name}" rescue nil
      str["{{#{refer_doc_tab.company_name}}}"] = "#{refer_doc.company_name}" rescue nil

      str["{{#{refer_doc_tab.address}}}"] = "#{refer_doc.address}" rescue nil
      str["{{#{refer_doc_tab.city}}}"] = "#{refer_doc.city}" rescue nil
      state , country = contact.get_state_country_name rescue nil
      str["{{#{refer_doc_tab.state}}}"] = "#{state}" rescue nil
      str["{{#{refer_doc_tab.country}}}"] = "#{country}" rescue nil
      str["{{#{refer_doc_tab.post_code}}}"] = "#{refer_doc.post_code}" rescue nil
      str["{{#{refer_doc_tab.occupation}}}"] = "#{refer_doc.occupation}" rescue nil
      str["{{#{refer_doc_tab.notes}}}"] = "#{refer_doc.notes}" rescue nil
      str["{{#{refer_doc_tab.provider_number}}}"] = "#{refer_doc.provider_number}" rescue nil

    end

    #   key value for general tab
    general_tab = GeneralTab.first
    str["{{#{general_tab.current_date}}}"] = Date.today

    return str
  end

  def stop_activity
    SmsLog.public_activity_off
  end

  def get_country_code_from_obj(id, ob_type)
    c_code= nil
    country_name = nil
    if ob_type.eql? 'patient'
      pt = Patient.find_by_id(id)
      country_name = pt.try(:country)
    elsif ob_type.eql? 'contact'
      contact = Contact.find_by_id(id)
      country_name = contact.try(:country)
    end
    c_code = ISO3166::Country.new(country_name).try(:country_code)
    return c_code
  end

  def get_pagination_detail(per_page  , page_no ,count)
    pagination = {}
    if page_no <= 1
      previous_page = nil
      next_page = ((per_page * page_no) < count) ?  (page_no + 1) : nil
    else
      previous_page = page_no - 1
      next_page = ((per_page * page_no) < count) ?  (page_no + 1) : nil
    end
    pagination[:prev_page] = previous_page
    pagination[:next_page] = next_page
    pagination[:total] = count
    return pagination
  end

  def get_sms_logs(start_date , end_date , user_id , per_pages)
    smslogs = []
    if (start_date.nil? && end_date.nil?)
      if user_id.nil?
        smslogs = @company.sms_logs.order("created_at desc").paginate(:page => params[:page] , :per_page=> per_pages )
      else
        smslogs = @company.sms_logs.where(['user_id = ?', user_id]).order("created_at desc").paginate(:page => params[:page] , :per_page=> per_pages )
      end
    else
      if user_id.nil?
        smslogs = @company.sms_logs.where(["DATE(delivered_on) >= ? AND DATE(delivered_on) <= ? ", start_date, end_date]).order("created_at desc").paginate(:page => params[:page] , :per_page=> per_pages )
      else
        smslogs = @company.sms_logs.where(["user_id = ? AND DATE(delivered_on) >= ? AND DATE(delivered_on) <= ? ", user_id , start_date, end_date]).order("created_at desc").paginate(:page => params[:page] , :per_page=> per_pages )
      end
    end
    return smslogs
  end


end