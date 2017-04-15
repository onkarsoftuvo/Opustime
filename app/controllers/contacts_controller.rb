class ContactsController < ApplicationController
  include Opustime::Utility
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain
  before_action :find_contact, :only => [:edit, :update, :destroy, :sms_items, :send_sms]
  before_action :set_params_in_format, :only => [:create, :update]

  # before_action :prevent_access_from_unauth
  # before_action :stop_delete_unauth, :only => [:destroy]

  load_and_authorize_resource   param_method: :contact_params , except: [:sms_items , :send_sms]
  before_filter :load_permissions

  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    # contacts= @company.contacts.specific_attributes.active_contact.order("created_at desc")
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : Contact.per_page
    unless params[:q].blank? || params[:q].nil?
      q = params[:q]
      arr = q.split(" ")
      if arr.length == 2
        contacts = @company.contacts.order("created_at desc").active_contact.select("id, first_name , last_name , phone_list , occupation , company_name").where(["(first_name LIKE ? AND last_name LIKE ?)OR (first_name LIKE ? AND last_name LIKE ?) OR occupation LIKE ? OR company_name LIKE ? ", "%#{arr.first}%", "%#{arr.last}%", "%#{arr.last}%", "%#{arr.first}%", "%#{params[:q]}%", "%#{params[:q]}%"]).paginate(:page => params[:page] , per_page: per_page )
     else
        contacts = @company.contacts.order("created_at desc").active_contact.select("id, first_name , last_name , phone_list , occupation , company_name").where(["first_name LIKE ? OR last_name LIKE ? OR occupation LIKE ? OR company_name LIKE ? ", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"]).paginate(:page => params[:page] , per_page: per_page)
      end
    else
      contacts = @company.contacts.order("created_at desc").active_contact.select("id, first_name , last_name , phone_list , occupation , company_name").paginate(:page => params[:page] , per_page: per_page)
    end

    contacts_list = []
    contacts.each do |item|
      contact = {}
      contact[:id] = item.id
      contact[:first_name] = item.first_name
      contact[:last_name] = item.last_name
      contact[:phone_list] = {}
      contact_contact_no = item.contact_nos.first
      unless contact_contact_no.nil?
        contact_info = {}
        contact_info[:contact_no] = (contact_contact_no.contact_number.nil? ? contact_contact_no.contact_number : contact_contact_no.contact_number.phony_formatted(format: :international, spaces: '-'))
        contact_info[:type] = contact_contact_no.contact_type

        contact[:phone_list] = contact_info
      else
        contact[:phone_list] = nil
      end

      contact[:occupation] = item.occupation
      contact[:company_name] = item.company_name
      contacts_list << contact
    end

    render :json => {contacts_list: contacts_list, total: contacts.count }

  end

  def new
    contact = @company.contacts.new
    render :json => {contact: contact}

  end

  def create
    contact = @company.contacts.new(contact_params)
    if contact.valid?
      contact.save
      result = {flag: true, id: contact.id}
      render :json => result

    else
      Add_custom_error_msg(contact)
      show_error_json(contact.errors.messages)
    end
  end

  def edit
    contact_list = []
    contact_first = @contact
    result = {}

    result[:id] = contact_first.id
    result[:contact_type] = contact_first.contact_type
    result[:title] = contact_first.title
    result[:first_name] = contact_first.first_name
    result[:last_name] = contact_first.last_name
    result[:preffered_name] = contact_first.preffered_name
    result[:phone_list] = []
    @contact.contact_nos.each do |ca|
      contact_info = {}
      contact_info[:id] = ca.id
      contact_info[:contact_no] = (ca.contact_number.nil? ? ca.contact_number : ca.contact_number.phony_formatted(format: :international, spaces: '-'))
      contact_info[:type] = ca.contact_type
      result[:phone_list] << contact_info
    end
    result[:occupation] = contact_first.occupation
    result[:company_name] = contact_first.company_name
    result[:email] = contact_first.email
    result[:city] = contact_first.city
    result[:state] = contact_first.state
    result[:post_code] = contact_first.post_code
    result[:country] = contact_first.country
    result[:notes] = contact_first.notes
    result[:address] = contact_first.address
    result[:next] = contact_first.next_contact
    result[:prev] = contact_first.prev_contact
    contact_list << result[:phone_list]
    render :json => result
  end

  def update
    contact = @contact
    contact.assign_attributes(contact_params)
    if contact.valid?
      contact.save
      result = {flag: true, id: contact.id}
      render :json => result

    else
      Add_custom_error_msg(contact)
      show_error_json(contact.errors.messages)
    end
  end

  def destroy
    contact = @contact
    # contact.update_columns(status: false)
    if  contact.update_columns(status: false)
      render :json => {flag: true}
    else
      show_error_json(contact.errors.messages)
    end
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
      if params[:receiver].present?
        sms_type = SMS_TYPE[1]

        # Getting all unique numbers on which sms has to be delivered
        contact_nos = []
        params["receiver"].map { |rc| contact_nos << rc[:contact] }
        contact_nos = contact_nos.flatten.uniq

        contact_ids = []
        params["receiver"].map { |rc| contact_ids << rc[:id] }
        contact_ids = contact_ids.flatten.uniq
        # country_name = @contact.country
        # c_code = ISO3166::Country.new(country_name).try(:country_code)
        # Getting number wise patients and sending sms and creating their logs
        contact_nos.each do |mob_no|
          mob_no = mob_no.phony_formatted(format: :international, spaces: '').phony_normalized
          contacts_having_number = @company.contacts.active_contact.joins(:contact_nos).where(["contact_number = ?", "#{mob_no}"])
          send_status = false

          # sending sms to all pateints having same numbers
          obj_ids = []
          obj_type = nil
          sm_body = nil
          contacts_having_number.each_with_index do |contact, index|
            sms_send_number = @company.sms_setting.default_sms
            if sms_send_number > 0
              accurate_no = mob_no

              # removing extra spaces from html
              coming_sms = params[:msg].split(',').map{|k| k.gsub(/[[:space:]]/ ,'') }
              coming_sms = coming_sms.map{|k|  (k.blank? || k.empty?) ? coming_sms.delete(k) : k }.join(',')
              half_msg = coming_sms.split('<').map{|k| k.gsub(/[[:space:]]/ ,'') }.join('<')
              coming_sms = half_msg.split('>').map{|k|  k.gsub(/[[:space:]]/ ,'') }.join('>')
              (coming_sms = coming_sms + '>') if half_msg.last == '>'

              # here

              body_with_html = make_dynamic_sms_content(coming_sms, contact.id, params[:obj_type], params[:doctor_id], params[:bs_id], params[:contact_id])
              sms_body = Nokogiri::HTML(body_with_html).text # purpose of nokogiri is to convert html_text into plain text

              # sending sms one time for all patients having same numbers

              if contact_ids.include?(contact.id)
                plivo_instance = PlivoSms::Sms.new
                response = plivo_instance.send_sms(src_no, accurate_no, sms_body)
                send_status = true if [200, 202].include? response[0]
                obj_type = contact.class.name
                sm_body = sms_body
                sms_send_number = sms_send_number - 1
                @company.sms_setting.update_attributes(:default_sms => sms_send_number)
              end
              obj_ids << contact.id
              result = {flag: true}
            end
          end

          # Creating sms logs for all patients
          obj_ids.each do |id|
            if send_status
              SmsLog.public_activity_off
              sms_log = @company.sms_logs.create(contact_to: mob_no, contact_from: src_no, sms_type: sms_type, delivered_on: DateTime.now, status: LOG_STATUS[0], contact_id: id, sms_text: sm_body, object_id: id, object_type: obj_type , user_id: current_user.id)
              communication = Communication.create(comm_time: Time.now, comm_type: "sms", category: "SMS Message", direction: "sent", to: mob_no, from: src_no, message: sm_body, send_status: true)
              receiver_person = sms_log.object   # choose any one of them

              SmsLog.public_activity_on
              sms_log.create_activity :create, parameters: sms_log.create_activity_log(current_user, receiver_person, mob_no, sm_body)
              result = {flag: true}
            else
              SmsLog.public_activity_off
              sms_log = @company.sms_logs.create(contact_to: mob_no, contact_from: src_no, sms_type: sms_type, delivered_on: DateTime.now, status: LOG_STATUS[1], contact_id: id, sms_text: sm_body, object_id: id, object_type: obj_type, user_id: current_user.id)
              communication = Communication.create(comm_time: Time.now, comm_type: "sms", category: "SMS Message", direction: "fail", to: mob_no, from: src_no, message: sm_body, send_status: false)
              receiver_person = (sms_log.object) # choose any one of them

              SmsLog.public_activity_on
              sms_log.create_activity :create, parameters: sms_log.create_activity_log(current_user, receiver_person, mob_no, sm_body)
            end
          end
        end
      end
      if result[:flag] == true
        render :json => result
      else
        if @company.sms_setting.default_sms <= 0
          sms_default = SmsSetting.new
          sms_default.errors.add('', 'SMS credits balance is low !')
          show_error_json(sms_default.errors.messages)
        else
          sms_default = SmsSetting.new
          sms_default.errors.add(:for_sms, 'please purchase a number !')
          show_error_json(sms_default.errors.messages)
        end
      end
    else
      result = {flag: false, :error => "please purchase a number !"}
      render :json => result
    end
  end

  def Add_custom_error_msg(contact)
    unless contact.errors.messages[:"contact_nos.contact_number"].nil?
      contact.errors.messages.delete(:"contact_nos.contact_number")
      contact.errors.add(:Phone_number, "is Invalid")
    end
  end

  def sms_items
    result = {}
    unless @contact.nil?
      result[:id] = @contact.id
      result[:name] = @contact.full_name
      result[:number] = @contact.get_primary_contact(params["num"])
      result[:conversation] = @contact.get_previous_conversations(params["num"])
    end
    render :json => result

  end

  def check_security_role
    result = {}
    result[:view] = can? :index , Contact
    result[:create] = can? :create , Contact
    result[:modify] = can? :update , Contact
    result[:delete] = can? :destroy , Contact
    render :json => result
  end

  private

  def contact_params
    params.require(:contact).permit(:id, :contact_type, :title, :first_name, :last_name, :preffered_name, :occupation, :company_name, :provider_number,
                                    {phone_list: [:contact_no, :type]}, :email, :address, :city, :state, :post_code, :country, :notes, :status,
                                    :contact_nos_attributes => [:id, :contact_number, :contact_type, :_destroy]).tap do |whitelisted|
      if (params[:post_code].nil?)
        whitelisted[:post_code] = nil
      else
        whitelisted[:post_code] = params[:post_code].upcase
      end
      end
  end

  def find_contact
    @contact = @company.contacts.active_contact.where(:id => params[:id]).try(:first)
  end

  # Filter to prevent access of scheduler 
  def prevent_access_from_unauth
    role = current_user.role
    if role.casecmp(ROLE[0]) == 0 || role.casecmp(ROLE[3]) == 0
      render :json => {:restricted => "user unauthorized"}
    end
  end

  # Filter to prevent delete expense from unauthorized users - Scheduler  Receptionist  Practitioner

  def stop_delete_unauth
    role = current_user.role
    if role.casecmp(ROLE[1]) == 0 || role.casecmp(ROLE[2]) == 0
      render :json => {:restricted => "user unauthorized"}
    end
  end


  def set_params_in_format
    params[:contact][:contact_nos_attributes] = []
    avail_ids =[]
    params[:contact][:phone_list].each do |phone_no|
      item = {}
      item[:id] = phone_no[:id] unless phone_no[:id].nil?
      avail_ids << phone_no[:id] unless phone_no[:id].nil?
      item[:contact_number] = phone_no[:contact_no]
      item[:contact_type] = phone_no[:type]
      params[:contact][:contact_nos_attributes] << item
    end unless params[:contact][:phone_list].nil?


    # adding destroy key for deleted records
    unless params[:action] == "create"
      unless avail_ids.length == 0
        deleted_records = @contact.contact_nos.where('id NOT IN (?)', avail_ids)
      else
        deleted_records = @contact.contact_nos
      end
      deleted_records.each do |record|
        item = {}
        item[:id] = record.id
        item[:_destroy] = true
        params[:contact][:contact_nos_attributes] << item
      end
    end
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
      str["{{#{pt_tab.full_name}}}"] = "#{patient.full_name}"
      str["{{#{pt_tab.title}}}"] = "#{patient.title}"
      str["{{#{pt_tab.first_name}}}"] = "#{patient.first_name}"
      str["{{#{pt_tab.last_name}}}"] = "#{patient.last_name}"
      str["{{#{pt_tab.mobile_number}}}"] = "#{patient.get_mobile_no_type_wise("mobile")}"
      str["{{#{pt_tab.home_number}}}"] = "#{patient.get_mobile_no_type_wise("home")}"
      str["{{#{pt_tab.work_number}}}"] = "#{patient.get_mobile_no_type_wise("work")}"
      str["{{#{pt_tab.fax_number}}}"] = "#{patient.get_mobile_no_type_wise("fax")}"
      str["{{#{pt_tab.other_number}}}"] = "#{patient.get_mobile_no_type_wise("other")}"
      str["{{#{pt_tab.email}}}"] = "#{patient.email}"
      str["{{#{pt_tab.address}}}"] = "#{patient.address}"
      str["{{#{pt_tab.city}}}"] = "#{patient.city}"
      str["{{#{pt_tab.post_code}}}"] = "#{patient.postal_code}"
      str["{{#{pt_tab.state}}}"] = "#{patient.state}"
      str["{{#{pt_tab.country}}}"] = "#{patient.country}"
      str["{{#{pt_tab.gender}}}"] = "#{patient.gender}"
      str["{{#{pt_tab.occupation}}}"] = "#{patient.occupation}"
      str["{{#{pt_tab.emergency_contact}}}"] = "#{patient.emergency_contact}"
      str["{{#{pt_tab.referral_source}}}"] = "#{patient.get_referral_source}" #
      str["{{#{pt_tab.medicare_number}}}"] = "#{patient.medicare_number}"
      # str["{{#{pt_tab.old_reference_id}}}"] = "#{patient.get_old_reference_id}"  #
      str["{{#{pt_tab.id_number}}}"] = "#{patient.id}"
      str["{{#{pt_tab.notes}}}"] = "#{patient.notes}"
      # str["{{#{pt_tab.first_appt_date}}}"] = "#{patient.get_first_appt_date}"  #
      # str["{{#{pt_tab.first_appt_time}}}"] = "#{patient.get_first_appt_time}"  #
      # str["{{#{pt_tab.most_recent_appt_date}}}"] = "#{patient.get_most_recent_appt_date}"  #
      # str["{{#{pt_tab.most_recent_appt_time}}}"] = "#{patient.get_most_recent_appt_time}" #
      # str["{{#{pt_tab.next_appt_date}}}"] = "#{patient.get_next_appt_date}" #
      # str["{{#{pt_tab.next_appt_time}}}"] = "#{patient.get_next_appt_time}" #
    end
    # key value for practitoner  tab
    unless practitioner.nil?
      pract_tab = PractitionerTab.first
      str["{{#{pract_tab.full_name}}}"] = "#{practitioner.full_name}"
      str["{{#{pract_tab.full_name_with_title}}}"] = "#{practitioner.full_name_with_title}"
      str["{{#{pract_tab.title}}}"] = "#{practitioner.title}"
      str["{{#{pract_tab.first_name}}}"] = "#{practitioner.first_name}"
      str["{{#{pract_tab.last_name}}}"] = "#{practitioner.last_name}"
      str["{{#{pract_tab.designation}}}"] = "#{practitioner.try(:practi_info).try(:designation)}"
      str["{{#{pract_tab.email}}}"] = "#{practitioner.email}"
      str["{{#{pract_tab.mobile_number}}}"] = "#{practitioner.phone}"
    end
    #  key value for business tab
    unless business.nil?
      bs_tab = BusinessTab.first
      str["{{#{bs_tab.name}}}"] = "#{business.name}"
      str["{{#{bs_tab.full_address}}}"] = "#{business.full_address}" #
      str["{{#{bs_tab.address}}}"] = "#{business.address}"
      str["{{#{bs_tab.city}}}"] = "#{business.city}"
      str["{{#{bs_tab.state}}}"] = "#{business.state}"
      str["{{#{bs_tab.post_code}}}"] = "#{business.pin_code}"
      str["{{#{bs_tab.country}}}"] = "#{business.country}"
      str["{{#{bs_tab.registration_name}}}"] = "#{business.reg_name}"
      str["{{#{bs_tab.registration_value}}}"] = "#{business.reg_number}"
      str["{{#{bs_tab.website_address}}}"] = "#{business.web_url}"
      str["{{#{bs_tab.ContactInformation}}}"] = "#{business.contact_info}"
    end
    # key value for contact tab
    unless contact.nil?
      cont_tab = ContactTab.first
      str["{{#{cont_tab.full_name}}}"] = "#{contact.full_name}" #
      str["{{#{cont_tab.title}}}"] = "#{contact.title}"
      str["{{#{cont_tab.first_name}}}"] = "#{contact.first_name}"
      str["{{#{cont_tab.last_name}}}"] = "#{contact.last_name}"
      str["{{#{cont_tab.preferred_name}}}"] = "#{contact.preffered_name}"
      str["{{#{cont_tab.company_name}}}"] = "#{contact.company_name}" #
      str["{{#{cont_tab.mobile_number}}}"] = "#{contact.get_mobile_no_type_wise("mobile")}"

      str["{{#{cont_tab.home_number}}}"] = "#{contact.get_mobile_no_type_wise("home")}"
      str["{{#{cont_tab.work_number}}}"] = "#{contact.get_mobile_no_type_wise("work")}"
      str["{{#{cont_tab.fax_number}}}"] = "#{contact.get_mobile_no_type_wise("fax")}"
      str["{{#{cont_tab.other_number}}}"] = "#{contact.get_mobile_no_type_wise("other")}"
      str["{{#{cont_tab.email}}}"] = "#{contact.email}"
      str["{{#{cont_tab.address}}}"] = "#{contact.address}"
      str["{{#{cont_tab.city}}}"] = "#{contact.city}"
      str["{{#{cont_tab.state}}}"] = "#{contact.state}"
      str["{{#{cont_tab.post_code}}}"] = "#{contact.post_code}"
      str["{{#{cont_tab.country}}}"] = "#{contact.country}"
      str["{{#{cont_tab.occupation}}}"] = "#{contact.occupation}"
      str["{{#{cont_tab.notes}}}"] = "#{contact.notes}"
      str["{{#{cont_tab.provider_number}}}"] = "#{contact.provider_number}"
    end
    # key value for refer doc tab
    unless refer_doc.nil?
      refer_doc_tab = ReferringDoctorTab.first
      str["{{#{refer_doc_tab.full_name}}}"] = "#{refer_doc.full_name}"
      str["{{#{refer_doc_tab.title}}}"] = "#{refer_doc.title}"
      str["{{#{refer_doc_tab.first_name}}}"] = "#{refer_doc.first_name}"
      str["{{#{refer_doc_tab.last_name}}}"] = "#{refer_doc.last_name}"
      str["{{#{refer_doc_tab.email}}}"] = "#{refer_doc.email}"
      str["{{#{refer_doc_tab.mobile_number}}}"] = "#{refer_doc.get_mobile_no_type_wise("mobile")}"
    end

    #   key value for general tab
    general_tab = GeneralTab.first
    str["{{#{general_tab.current_date}}}"] = Date.today
    return str
  end


end


# {
# "contact": {
# "id": null,
# "contact_type": null,
# "title": null,
# "first_name": null,
# "last_name": null,
# "preffered_name": null,
# "occupation": null,
# "company_name": null,
# "provider_number": null,
# "phone_list": [{:contact_no=>9501222018, :type=>"mobile"}],
# "email": null,
# "address_1": null,
# "address_2": null,
# "address_3": null,
# "city": null,
# "state": null,
# "post_code": null,
# "country": null,
# "notes": null,
# }
# }