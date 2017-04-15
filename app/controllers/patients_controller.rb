class PatientsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include PlivoSms
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain #, :only =>[:index , :create , :doctors_list , :referral_list , :list_related_patients , :list_contact , :account_statement , :account_history , :clients_modules, :account_statement_pdf , :send_email , :get_patient_submodules_total , :send_sms]
  before_action :find_patient, :only => [:edit, :update, :destroy, :show, :permanent_delete, :status_active, :account_statement, :account_history, :clients_modules, :send_email, :get_patient_submodules_total, :account_statement_pdf, :identical, :patient_merge, :has_patient_wait_list, :send_sms, :sms_items]
  before_action :set_params_in_format, :only => [:create, :update]

  # load_and_authorize_resource  param_method: :params_patient , :only=> [:index , :new ,  :create]  #, :except => [:clients_modules , :user_role_wise_authority , :get_patient_submodules_total , :show , :edit , :update , :destroy , :account_history , :account_statement , :account_statement_pdf , :send_email , :doctors_list , :list_contact , :list_related_patients , :status_active , :permanent_delete , :has_patient_wait_list , :identical , :patient_merge]
  # before_filter :load_permissions

  # using only for postman to test API. Remove later
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : Patient.per_page
    unless params[:q].blank? || params[:q].nil?
      q = params[:q]
      arr = q.split(" ")
      if arr.length == 2
        patients = @company.patients.active_patient.specific_attributes_for_index.order("created_at desc").where(["(patients.first_name LIKE ? AND patients.last_name LIKE ?) OR (patients.first_name LIKE ? AND patients.last_name LIKE ?) OR patients.email LIKE ? OR reference_number LIKE ?", "%#{arr.first}%", "%#{arr.last}%", "%#{arr.last}%", "%#{arr.first}%", "%#{params[:q]}%", "%#{params[:q]}%"]).paginate(:page => params[:page] , per_page: per_page)
      else
        patients = @company.patients.active_patient.specific_attributes_for_index.order("created_at desc").where(["patients.first_name LIKE ? OR patients.last_name LIKE ? OR patients.first_name LIKE ? OR patients.last_name LIKE ? OR patients.email LIKE ? OR reference_number LIKE ?", "%#{arr.first}%", "%#{arr.first}%", "%#{arr.last}", "%#{arr.last}%", "%#{params[:q]}%", "%#{params[:q]}%"]).paginate(:page => params[:page] , per_page: per_page)
      end

    else
      patients = @company.patients.active_patient.specific_attributes_for_index.order("created_at desc").paginate(:page => params[:page] , per_page: per_page)
    end
    patient_list = []
    patients.each do |item|
      patient = {}
      patient[:id] = item.id
      patient[:full_name] = item.first_name.to_s + " " + item.last_name.to_s
      patient[:dob] = item.dob
      unless item.patient_contacts.try(:first).nil?
        patient[:mobile_no] = (item.patient_contacts.first.contact_no.nil? ? nil : (item.patient_contacts.first.contact_no.phony_formatted(format: :international, spaces: '-')))
        patient[:contact_type] = item.patient_contacts.first.contact_type
      end

      patient[:email] = item.email
      if item.next_appointment.nil?
        patient[:next_apt] = "NA"
        patient[:next_apt_id] = nil
      else
        next_appnt = item.next_appointment
        patient[:next_apt] = next_appnt.date_and_time_without_name.to_date.try(:strftime, "On %A,%dTH %^b %Y %l:%M %p")
        patient[:next_apt_id] = next_appnt.try(:id)
        patient[:next_appointment_date] = next_appnt.appnt_date.to_date.strftime("On %d %b %Y").to_s
        patient[:next_appointment_time] = next_appnt.appnt_time_start.strftime(", %H:%M%p").to_s
      end
      patient[:status] = item.status
      patient_list << patient
    end

    render :json => {patient_list: patient_list , total: patients.count }

  end



  def new
    (authorize! :new , Patient) unless (can? :new , Patient)
    render :json=> {:status=> true}
  end

  def create
    set_blank_patient_contact(params)
    patient = @company.patients.new(params_patient)
    if patient.valid?

#     To set relationship attributes
      set_relation(patient, params)
      patient.with_lock do
        patient.save
      end

      result = {flag: true, patient_id: patient.id}
      render :json => result
    else
      Add_custom_error_msg(patient)
      show_error_json(patient.errors.messages)
    end
  end

  def show
    authorize! :show , Patient unless (can? :show , Patient)
    result = {}
    if @patient.length > 0
      delete_cookies
      patient = @patient.first
      session.delete 'patient_id'
      session[:patient_id] = patient.id
      result = set_patient_format(patient)
    else
      result[:error] = 'No patient exists!'
    end
    render :json => result
  end

  def edit
    (authorize! :edit , Patient) unless (can? :edit , Patient)
    result = {}
    if @patient.length > 0
      patient = @patient.first
      result = set_patient_format(patient)
    else
      result[:error] = "no data"
    end

    render :json => result
  end

  def update
    (authorize! :update , Patient) unless (can? :update , Patient)
    result = {}
    if @patient.length > 0
      patient = @patient.first
      #  calling method to add _destroy params in deleted items
      set_blank_patient_contact(params)
      add_destory_key_to_params(params, patient)

      # patient.assign_attributes(params_patient)
      patient.relationship = []
      set_relation(patient, params)
     patient.update_attributes(params_patient)
      if patient.save
        result = {flag: true}
        render :json => result
      else
        Add_custom_error_msg(patient)
        Add_custom_error_zip_msg(patient)
        show_error_json(patient.errors.messages)
      end
    else
      result[:error] = "no data"
    end

  end

  def destroy
    (authorize! :destroy , Patient) unless (can? :destroy , Patient)
    result = {}
    if @patient.length > 0
      patient = @patient.first

      if  patient.update_columns(:status => STATUS[2])
        archive_date = patient.updated_at.strftime("%dth %b %Y")
        result = {flag: true, archive_at: archive_date}
        render :json => result
      else
        show_error_json(patient.errors.messages)
      end
    else
      result[:error] = "no data"
    end
  end

  def permanent_delete
    (authorize! :permanent_delete , Patient) unless (can? :permanent_delete , Patient)
    result = {}
      if @patient.length > 0
      patient = @patient.first
      if patient.update_columns(:status => STATUS[3])
        result = {flag: true}
        render :json => result
      else
        show_error_json(patient.errors.messages)
      end
    else
      result[:error] = "no data"
    end
  end

  def status_active
    (authorize! :status_active , Patient) unless (can? :status_active , Patient)
    result = {}
    if @patient.length > 0
      patient = @patient.first
      if patient.update_columns(:status => STATUS[1])
        result = {flag: true}
        render :json => result
      else
        show_error_json(patient.errors.messages)
      end
    else
      result[:error] = "no data"
    end

  end

  def doctors_list
    doctors = @company.contacts.where(contact_type: "Doctor", status: true).select("id , first_name , last_name")
    render :json => doctors
  end

  def list_related_patients
    patient = @company.patients.active_patient.select("id, first_name , last_name").order("created_at desc")
    patient_list = []
    patient.each do |item|
      patient = {}
      patient[:id] = item.id
      patient[:first_name] = item.first_name
      patient[:last_name] = item.last_name
      patient_list << patient
    end
    render :json => patient_list
  end

  def list_contact
    referral = @company.contacts.select("id , first_name , last_name")
    render :json => referral
  end

  #   Patient 's account statement info
  def account_statement
    (authorize! :account_statement , Patient) unless (can? :account_statement , Patient)
    result = {}
    save_filter_params_into_cookies(params) # saving filter params into cookies for pdf
    patient = @patient.first
    business = @company.businesses.head.first
    patient.get_business_detail_info(result, business)
    result[:filter_from] = (params[:start_date].nil? ? params[:start_date] : params[:start_date].to_date.strftime("%d %b %Y"))
    result[:filter_to] = (params[:end_date].nil? ? params[:end_date] : params[:end_date].to_date.strftime("%d %b %Y"))
    result[:patient_outstanding_balance] = patient.calculate_patient_outstanding_balance(params[:start_date], params[:end_date])
    result[:patient_name] = patient.full_name
    result[:patient_email] = patient.email
    result[:patient_other_email] = patient.invoice_email
    result[:extra_business_info] = @company.invoice_setting.extra_bussiness_information
    result[:default_notes] = @company.invoice_setting.default_notes
    result[:business_reg_name] = business.reg_name
    result[:business_reg_number] = business.reg_number
    result[:include_extra_patient_info] = params[:extra_patient_info].nil? ? false : params[:extra_patient_info]
    result[:extra_patient_info] = patient.invoice_extra_info if params[:extra_patient_info] == true
    result[:has_patient_invoice_to] = !patient.invoice_to.nil?
    if params[:patient_invoice_to].nil? || params[:patient_invoice_to] == "false" || params[:patient_invoice_to] == false
      result[:invoice_to] = patient.default_invoice_to
    else
      result[:invoice_to] = patient.invoice_to
    end
    result[:invoices] = patient.get_invoices(params[:start_date], params[:end_date], params[:show_outstanding_invoice].nil? ? false : params[:show_outstanding_invoice])
    if params[:hide_payment].nil?
      result[:payments] = patient.get_payments(params[:start_date], params[:end_date])
    else
      result[:payments] = params[:hide_payment] ? [] : patient.get_payments(params[:start_date], params[:end_date])
    end
    render :json => result
  end

  #   Display account statement in pdf
  def account_statement_pdf
    authorize! :account_statement_pdf , Patient unless (can? :account_statement_pdf , Patient)
    fetch_filter_from_cookies_to_params(params) # getting filter params from cookies for pdf

#   Getting setting info for print from setting/document and printing
    print_setting = @company.document_and_printing
    @title = print_setting.as_title
    @logo_url = print_setting.logo
    @logo_size = print_setting.logo_height


    @result = get_account_statement_data
    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => "pdf_name.pdf",
               :layout => "/layouts/pdf.html.erb",
               :disposition => 'inline',
               :template => "/patients/account_statement_pdf",
               :show_as_html => params[:debug].present?,
               :footer => {right: '[page] of [topage]'}
      end
    end
  end

  #   To get identical patients for merge
  def identical
    (authorize! :identical , Patient) unless (can? :identical , Patient)
    result = []
    patient = @patient.first
    company = patient.company
    identical_patients = company.patients.active_patient.where('lower(first_name) = ? AND lower(last_name) = ? AND id != ? ', patient.first_name.downcase, patient.last_name.downcase, patient.id).select("id , first_name , last_name , dob , created_at ")
    identical_patients.each do |similar_patient|
      item = {}
      item[:id] = similar_patient.id
      item[:name] = similar_patient.first_name.to_s + " " + similar_patient.last_name.to_s
      if similar_patient.patient_contacts.where(contact_type: "mobile").first.nil?
        item[:mobile_no] = nil
      else
        item[:mobile_no] = similar_patient.patient_contacts.length == 0 ? nil : similar_patient.patient_contacts.where(contact_type: "mobile").first.contact_no.phony_formatted(format: :international, spaces: '-')
      end

      item[:dob] = similar_patient.dob.strftime("%d %b %Y") rescue nil
      item[:created] = similar_patient.created_at.strftime("%d %b %Y")
      result << item
    end
    render :json => {identical_patients: result}
  end

  #   Functionality to merge existing one patient.
  def patient_merge
    (authorize! :patient_merge , Patient) unless (can? :patient_merge , Patient)
    TreatmentNote.current = current_user
    sm_patients = Patient.active_patient.where("id IN (?)", params[:identical_patients])
    sm_patients.each do |ptnt|
      # invoices = ptnt.invoices
      @patient.first.merge_blank_attributes(ptnt)
      @patient.first.invoices << ptnt.invoices
      @patient.first.payments << ptnt.payments
      @patient.first.medical_alerts << ptnt.medical_alerts
      @patient.first.treatment_notes << ptnt.treatment_notes
      @patient.first.communications << ptnt.communications
      @patient.first.recalls << ptnt.recalls
      @patient.first.letters << ptnt.letters
      # Shifting file attachments
      ptnt.file_attachments.each do |attach_file|
        @patient.first.file_attachments.create(:avatar => attach_file.avatar) if attach_file.avatar.exists?
        attach_file.destroy
      end
      ptnt.update_attributes(status: false)
    end
    render :json => {flag: true}

  end

  #   To patient's account history
  def account_history
    (authorize! :account_history  , Patient)   unless  (can? :account_history, Patient)
    @result = {}
    patient = @patient.first
    @result[:patient_name] = patient.full_name
    @result[:dob] = patient.dob.strftime("%d %b %Y") rescue nil
    @result[:occupation] = patient.occupation
    @result[:medicare_no] = patient.medicare_number
    @result[:appointments] = []
    @result[:treatment_notes] = []
    # @result[:treatment_notes] = patient.treatment_notes
#     Getting treatment notes to view in pdf

    if (@company.account.note_letter)
      if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
        treatment_notes = @patient.first.treatment_notes.active_treatment_note.order("created_at desc")
      else
        treatment_notes = @patient.first.treatment_notes.active_treatment_note.where(['created_by_id =? ' , current_user.id]).order("created_at desc")
      end
    else
      treatment_notes = @patient.first.treatment_notes.active_treatment_note.where(['created_by_id =? ' , current_user.id]).order("created_at desc")
    end
    treatment_note_view(treatment_notes, @result)
    @appointments = @patient.first.appointments.active_appointment
    @business_head = @company.businesses.head.first.try(:name)
    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => "pdf_name.pdf",
               :layout => '/layouts/pdf.html.erb',
               :disposition => 'inline',
               :template => "/patients/account_history",
               :show_as_html => params[:debug].present?,
               :footer => {html: {template: '/patients/history_report_footer', # use :template OR :url
                                  locals: {location: @business_head}},
                           line: true,
                           spacing: 10,
                           left: '[page] of [topage]'
               }
      end
    end
  end

  #   Getting listing of every submodules dates wise on client show page
  def clients_modules
    result = []
#   checking authority for filter for current user so that anyone can not make hit with extra parameters
    check_authority_for_filter(params)

#    Applying filter choice  for current user
    unless params[:filter].nil?
      set_client_filters_for_current_user(params[:filter].split(","), current_user) unless (params[:filter].split(",") - ["appointment", "treatment_note", "invoice", "payment", "recall", "letter", "file", "communication"]).length > 0
    end
    cookies.delete :date if params[:page].nil?
    cookies[:date] = get_patient_dates(@patient.first) if cookies[:date].nil?
#   local storage to check - is there any data available for a particular date
    cookies[:total_records] = 0
#   Getting data datewise minimum 10 and it will take all records for a particular date weather it is crossing 10 or not
    if cookies[:date].length > 0
#       Checking pagination hit having next_date or not
      if params[:next_date].nil?
        set_cookies_dates(nil, cookies[:date])
        result << get_all_data_of_modules_of_patient(cookies[:start_date])
      else
        cookies[:date]= cookies[:date].split("&").map { |k| k.to_date }
        set_cookies_dates(params[:next_date], cookies[:date])
        result << get_all_data_of_modules_of_patient(params[:next_date].to_date)
      end

      while (cookies[:total_records] < CLIENT_EVENT_SIZE && !(cookies[:next_date].try(:to_date).nil?))
        set_cookies_dates(cookies[:next_date].try(:to_date), cookies[:date])
        result << get_all_data_of_modules_of_patient(cookies[:start_date].to_date)
      end
    end
#   Adding next url hit with data for pagination purpose
    params_query_str = cookies[:next_date].blank? ? nil : "?next_date=#{cookies[:next_date].to_date.strftime('%d-%b-%Y')}&page=#{params[:page].to_i + 1}&filter=#{params[:filter]}"
    main_result = {next_hit: (!(params_query_str.nil?) ? "#{root_url}patients/#{params[:id]}/client_profile"+params_query_str : nil), modules: result.compact}

    render :json => main_result
  end

  #   To get the counting of every sub-modules to display on client page
  def get_patient_submodules_total
    result = {}
    patient = @patient.first

    # ********here

    if (@company.account.note_letter)
      if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
        result[:treatment_notes_count] = patient.treatment_notes.active_treatment_note.count
      else
        result[:treatment_notes_count] = patient.treatment_notes.active_treatment_note.where(['created_by_id =? ' , current_user.id]).count
      end
    else
      if can? :view_all , TreatmentNote
        result[:treatment_notes_count] = patient.treatment_notes.active_treatment_note.count
      else
        if can? :view_own , TreatmentNote
          result[:treatment_notes_count] = patient.treatment_notes.active_treatment_note.where(['created_by_id =? ' , current_user.id]).count
        else
          result[:treatment_notes_count] = 0
        end
      end
    end

    result[:invoices_count] = patient.invoices.active_invoice.count
    result[:payments_count] = patient.payments.active_payment.count
    result[:recalls_count] = patient.recalls.active_recall.count

    if (@company.account.note_letter)
      if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
        result[:letters_count] = patient.letters.active_letter.count
      else
        result[:letters_count] = patient.letters.active_letter.where(["auther_id = ? ", current_user.id]).count
      end
    else
      if can? :manage_own , Letter
        if can? :manage_all , Letter
          result[:letters_count] = patient.letters.active_letter.count
        else
          result[:letters_count] = patient.letters.active_letter.where(["auther_id = ? ", current_user.id]).count
        end
      else
        if can? :manage_all , Letter
          result[:letters_count] = patient.letters.active_letter.count
        else
          result[:letters_count] = 0
        end
      end
    end

    # if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
    #
    #   result[:letters_count] = patient.letters.active_letter.count
    # else
    #   result[:letters_count] = patient.letters.active_letter.where(["auther_id = ? ", current_user.id]).count
    # end

    result[:communications_count] = patient.communications.count
    result[:files_count] = patient.file_attachments.count
    result[:appointments_count] = patient.appointments.active_appointment.count
    render :json => result
  end

  #   To send email to patient or other
  def send_email
    (authorize! :account_statement , Patient) unless (can? :account_statement , Patient)
    fetch_filter_from_cookies_to_params(params) # getting filter params from cookies for pdf

    #   Getting setting info for print from setting/document and printing
    print_setting = @company.document_and_printing
    @title = print_setting.as_title
    @logo_url = print_setting.logo
    @logo_size = print_setting.logo_height
    @result = get_account_statement_data

    html = render_to_string(:action => :account_statement_pdf, :layout => "/layouts/pdf.html.erb", :formats => [:pdf], :locals => {:@result => @result})
    pdf = WickedPdf.new.pdf_from_string(html)
    @patient_info = @patient.first
    @business = @patient_info.company.businesses.head.first
    flag = params[:email_to].to_s.casecmp("patient") == 0 ? true : false
    greeting_text = flag ? "Hi #{@patient_info.first_name.capitalize}" : "hello"
    comm_msg = "<p> #{greeting_text}, </p><p> Please find attached your Account Statement.<p> Thank you </p><p>#{@business.name}</p>"
    communication = @patient_info.communications.build(comm_time: Time.now, comm_type: "email", category: "Account Statement", direction: "sent", to: @patient_info.email, from: @patient_info.company.communication_email, message: comm_msg, send_status: true)
    if communication.valid?
      communication.save
      begin
        PatientMailer.account_statement_email(@patient_info, params[:email_to], current_user, pdf).deliver_now
      rescue Exception => e
        puts e.message
      end
      result = {flag: true}
      render :json => result
    else
      show_error_json(communication.errors.messages)
    end
  end

  def send_sms

    if @patient.first.sms_marketing == false
      Rails.logger.info "============Inside ============="
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

          # Getting number wise patients and sending sms and creating their logs
          contact_nos.each do |mob_no|
            mob_no = mob_no.phony_formatted(format: :international, spaces: '').phony_normalized
            patients_having_number = @company.patients.active_patient.joins(:patient_contacts).where(["contact_no = ? ", "#{mob_no}"])
            send_status = false

            # sending sms to all patients having same numbers
            obj_ids = []
            obj_type = nil
            sm_body = nil
            Rails.logger.info "=========================total patient having same number --- #{patients_having_number.length}"
            patients_having_number.each_with_index do |patient, index|
              sms_send_number = @company.sms_setting.default_sms
              if sms_send_number > 0
                accurate_no = mob_no.phony_formatted(format: :international, spaces: '').phony_normalized

                coming_sms = params[:msg].split(',').map{|k| k.gsub(/[[:space:]]/ ,' ') }
                coming_sms = coming_sms.map{|k|  (k.blank? || k.empty?) ? coming_sms.delete(k) : k }.join(',')

                half_msg = coming_sms.split('<').map{|k| k.gsub(/[[:space:]]/ ,' ') }.join('<')
                coming_sms = half_msg.split('>').map{|k|  k.gsub(/[[:space:]]/ ,' ') }.join('>')
                (coming_sms = coming_sms + '>') if half_msg.last == '>'


                body_with_html = make_dynamic_sms_content(coming_sms , patient.id, params[:obj_type], params[:doctor_id], params[:bs_id], params[:contact_id])
                sms_body = Nokogiri::HTML(body_with_html.gsub(/<\/?[^>]+>/, '')).text # purpose of nokogiri is to convert html_text into plain text

                # sending sms one time for all patients having same numbers
                if contact_ids.include?(patient.id)
                  plivo_instance = PlivoSms::Sms.new
                  Rails.logger.info "=========================sco_no : #{src_no} --- destination number #{accurate_no}"
                  Rails.logger.info "=========================body : #{sms_body}"
                  response = plivo_instance.send_sms(src_no , accurate_no , sms_body)
                  send_status = true  if [200 , 202].include?response[0]
                  obj_type = patient.class.name
                  sm_body = sms_body
                  sms_send_number = sms_send_number - 1
                  @company.sms_setting.update_attributes(:default_sms => sms_send_number)
                end
                obj_ids << patient.id
                result = {flag: true}
              end
            end


            # Creating sms logs for all patients
            Rails.logger.info "=========================total patient having same number --- #{obj_ids.length}"
            obj_ids.each do |id|
              if send_status
                SmsLog.public_activity_off
                sms_log = @company.sms_logs.create(contact_to: mob_no, contact_from: src_no, sms_type: sms_type, delivered_on: DateTime.now, status: LOG_STATUS[0], patient_id: id, sms_text: sm_body, object_id: id, object_type: obj_type , user_id: current_user.id)
                communication = Communication.create(comm_time: Time.now, comm_type: "sms", category: "SMS Message", direction: "sent", to: mob_no, from: src_no, message: sm_body, send_status: true, :patient_id => id)
                receiver_person = (sms_log.object) # choose any one of them

                SmsLog.public_activity_on
                sms_log.create_activity :create, parameters: sms_log.create_activity_log(current_user, receiver_person, mob_no, sm_body)
                result = {flag: true}
              else
                SmsLog.public_activity_off
                sms_log = @company.sms_logs.create(contact_to: mob_no, contact_from: src_no, sms_type: sms_type, delivered_on: DateTime.now, status: LOG_STATUS[1], patient_id: id, sms_text: sm_body, object_id: id, object_type: obj_type , user_id: current_user.id)
                communication = Communication.create(comm_time: Time.now, comm_type: "sms", category: "SMS Message", direction: "fail", to: mob_no, from: src_no, message: sm_body, send_status: false, :patient_id => id)
                receiver_person = (sms_log.object)  # choose any one of them

                SmsLog.public_activity_on
                sms_log.create_activity :create, parameters: sms_log.create_activity_log(current_user, receiver_person, mob_no, sm_body)
              end
            end
          end
        end
        Rails.logger.info "flag value : #{result[:flag]}"
        if result[:flag] == true
          render :json => result
        else
          if @company.sms_setting.default_sms <= 0
            sms_default = SmsSetting.new
            sms_default.errors.add('', 'SMS credits balance is low')
            show_error_json(sms_default.errors.messages)
          else
            sms_default = SmsSetting.new
            sms_default.errors.add(:for_sms, 'please purchase a number !')
            show_error_json(sms_default.errors.messages)
          end

        end
      else
        Rails.logger.info "******************Company has no src no #{src_no}***********"
        result = {flag: false, :error => 'please purchase a number !'}
        render :json => result
      end
    else
      patient = Patient.new
      patient.errors.add(:Sorry, ', sms marketing is not enabled !')
      show_error_json(patient.errors.messages)
    end
  end

  def sms_items
    result = {}
    patient = @patient.first
    unless patient.nil?
      result[:id] = patient.id
      result[:name] = patient.full_name
      result[:number] = patient.get_primary_contact(params["num"])
      result[:conversation] = patient.get_previous_conversations(params["num"])
    end

    render :json => result
  end

  def user_role_wise_authority
    result = {}
    # patient = Patient.first

    #   patient details security role
    result[:read] = can? :index, Patient
    result[:create] = can? :create, Patient
    result[:modify] = can? :update, Patient
    result[:merge] = can? :patient_merge, Patient
    result[:history_report] = can? :account_history, Patient
    result[:account_statement] = can? :account_statement, Patient
    result[:archive_or_activate] = can? :destroy, Patient
    result[:delete] = can? :permanent_delete, Patient
    result[:send_sms] = can? :send_sms , Patient
    result[:has_options] = (result[:modify] || result[:merge] || result[:history_report] || result[:account_statement] || result[:archive_or_activate] || result[:delete])

    result[:treatment_note] = ((can? :view_own , TreatmentNote) || (can? :view_all , TreatmentNote) )
    result[:treatment_note_create] =  (can? :view_own , TreatmentNote)

    result[:letter] = ((can? :manage_own , Letter) || (can? :manage_all , Letter))
    result[:letter_create] = ((can? :manage_own , Letter) || (can? :manage_all , Letter))

    result[:invoice] = can? :index, Invoice
    result[:invoice_create] = can? :create, Invoice
    result[:payment] = can? :index, Payment
    result[:payment_create] = can? :create, Payment
    result[:recall] = can? :index, Recall
    result[:recall_create] = can? :create, Recall
    result[:file_attachment] = ((can? :viewname, FileAttachment) || (can? :viewfile, FileAttachment) || (can? :upload, FileAttachment))
    result[:file_attachment_create] = (can? :upload, FileAttachment)
    result[:communication] = can? :index, Communication
    result[:appointment] = can? :index  , Appointment
    result[:appointment_create] = can? :create  , Appointment
    result[:medical_alert] = can? :manage , MedicalAlert

    render :json => {result: result, role: current_user.role}
  end

  def check_authority_for_filter(params)
    a = params[:filter].nil? ? [] : params[:filter].split(",").collect(&:strip)
    if ((cannot? :view_own , TreatmentNote) && (cannot? :view_all , TreatmentNote))
      a.delete("treatment_note")
    end
    if cannot? :show, Letter
      a.delete("letter")
    end
    if cannot? :index, Invoice
      a.delete("invoice")
    end
    if cannot? :index, Payment
      a.delete("payment")
    end
    if cannot? :index, Recall
      a.delete("recall")
    end
    if ((cannot? :viewname, FileAttachment) && (cannot? :viewfile, FileAttachment))
      a.delete('file')
    end
    if cannot? :index, Communication
      a.delete("communication")
    end
    params[:filter] = a.join(",")
  end

  def has_patient_wait_list
    patient = @patient.first
    result = {flag: false}
    unless patient.nil?
      if patient.wait_list.try(:status) == true
        result = {flag: true, patient_id: patient.id, patient_name: patient.full_name, wait_list_id: patient.wait_list.id}
      end
    end
    render :json => result
  end

def upload
  patient = Patient.find(params[:patient_id])
  patient.update(:profile_pic => params[:file])
  if patient.valid?
    render :json=> {flag: true}
  else
    show_error_json(patient.errors.messages)
  end
end

  private

  def params_patient
    params.require(:patient).permit(:id, :title, :first_name, :last_name, :dob, :gender, {relationship: []}, :email, :reminder_type, :sms_marketing, :address, :country, :state, :city, :postal_code, :concession_type, :invoice_to, :invoice_email, :invoice_extra_info, :occupation, :emergency_contact, :medicare_number, :reference_number, :refer_doctor, :notes, :referral_type, :referrer, :extra_info, :status , :profile_pic ,
                                    {:concessions_patient_attributes => [:id, :concession_id, :_destroy]},
                                    {:patients_contact_attributes => [:id, :contact_id, :_destroy]},
                                    {:patient_contacts_attributes => [:id, :contact_no, :contact_type, :_destroy]}).tap do |whitelisted|
      whitelisted[:referrer] = params[:patient][:referrer] unless params[:patient][:referrer].nil?

      if (params[:patient][:referrer].nil?) || (params[:patient][:referrer].is_a?(String))
        whitelisted[:referral_id] = nil
      else
        whitelisted[:referral_id] = params[:patient][:referrer][:id]
      end
      if (params[:patient][:postal_code].nil?)
        whitelisted[:postal_code] = nil
      else
        whitelisted[:postal_code] = params[:patient][:postal_code].upcase
      end
    end
  end

  def set_params_in_format
    #managing patient_contact
    params[:patient][:patients_contact_attributes] = {}
    avail_ids =[]
    ref_doc = params[:patient][:refer_doctor]
    unless ref_doc.nil?
      item = {}
      item[:contact_id] = ref_doc[:id] unless ref_doc[:id].nil?
      avail_ids << ref_doc[:id] unless ref_doc[:id].nil?
      params[:patient][:patients_contact_attributes] = item
    end
    if params[:patient][:refer_doctor].nil?
      pc_id = params[:patient][:refer_doctor].to_i
    else
      pc_id = params[:patient][:refer_doctor][:contact_id].to_i
    end
    if pc_id > 0
      if params[:action] =="update"
        item = {}
        unless pc_id == @patient.first.contact.try(:id)
          item[:contact_id] = pc_id
          params[:patient][:patients_contact_attributes] = item
        else
          item[:id] = params[:patient][:refer_doctor][:id]
          item[:contact_id] = pc_id
          params[:patient][:patients_contact_attributes] = item
        end
      end
    else
      # adding destroy key for deleted records
      unless params[:action] == "create"
        unless pc_id == @patient.first.contact.try(:id)
          if avail_ids.length == 0
            deleted_records = @patient.first.patients_contact
            unless deleted_records.nil?
              item = {}
              item[:id] = deleted_records.try(:id)
              item[:_destroy] = true
              params[:patient][:patients_contact_attributes] = item
            end
          end
        end
      end
    end

    # managing concession
    params[:patient][:concessions_patient_attributes] = {}
    item = {}
    cs_id = params[:patient][:concession_type].to_i

    if cs_id > 0
      if params[:action] == "update"
        unless cs_id == @patient.first.concession.try(:id)
          item[:concession_id] = cs_id
          params[:patient][:concessions_patient_attributes] = item
        else
          record = ConcessionsPatient.where(["patient_id =? AND concession_id=? ", @patient.first.id, cs_id]).first
          item[:id] = record.try(:id)
          item[:concession_id] = cs_id
          params[:patient][:concessions_patient_attributes] = item
        end
      else
        item[:concession_id] = cs_id
        params[:patient][:concessions_patient_attributes] = item
      end
    else
      if params[:action] == "update"
        unless @patient.first.concession.nil?
          record = ConcessionsPatient.where(["patient_id =? AND concession_id=? ", @patient.first.id, @patient.first.concession.id]).first
          item[:id] = record.try(:id)
          item[:_destroy] = true
          params[:patient][:concessions_patient_attributes] = item
        end
      end
    end
  end

  def find_patient
    @patient = @company.patients.active_patient.where(:id => params[:id])
  end

  def save_filter_params_into_cookies(params)
    delete_cookies
    cookies[:pdf_start_date] = params[:start_date]
    cookies[:pdf_end_date] = params[:end_date]
    cookies[:pdf_show_outstanding_invoice] = params[:show_outstanding_invoice]
    cookies[:pdf_hide_payment] = params[:hide_payment]
    cookies[:pdf_extra_patient_info] = params[:extra_patient_info]
    cookies[:pdf_patient_invoice_to] = params[:patient_invoice_to]
  end

  def fetch_filter_from_cookies_to_params(params)
    params[:start_date] = cookies[:pdf_start_date].blank? ? nil : cookies[:pdf_start_date]
    params[:end_date] = cookies[:pdf_end_date].blank? ? nil : cookies[:pdf_end_date]
    params[:show_outstanding_invoice] = cookies[:pdf_show_outstanding_invoice].blank? ? nil : cookies[:pdf_show_outstanding_invoice].to_bool
    params[:hide_payment] = cookies[:pdf_hide_payment].blank? ? nil : cookies[:pdf_hide_payment].to_bool
    params[:extra_patient_info] = cookies[:pdf_extra_patient_info].blank? ? nil : cookies[:pdf_extra_patient_info].to_bool
    params[:patient_invoice_to] = cookies[:pdf_patient_invoice_to].blank? ? nil : cookies[:pdf_patient_invoice_to].to_bool
  end

  def get_account_statement_data
    @result = {}
    patient = @patient.first
    business = @company.businesses.head.first
    patient.get_business_detail_info(@result, business)
    @result[:filter_from] = ((params[:start_date].nil? || params[:start_date].blank?) ? params[:start_date] : params[:start_date].to_date.strftime("%d %b %Y"))
    @result[:filter_to] = ((params[:end_date].nil? || params[:end_date].blank?) ? params[:end_date] : params[:end_date].to_date.strftime("%d %b %Y"))
    @result[:patient_outstanding_balance] = patient.calculate_patient_outstanding_balance(params[:start_date], params[:end_date])
    @result[:patient_name] = patient.full_name
    @result[:extra_business_info] = @company.invoice_setting.extra_bussiness_information
    @result[:default_notes] = @company.invoice_setting.default_notes
    @result[:business_reg_name] = business.reg_name
    @result[:business_reg_number] = business.reg_number
    @result[:include_extra_patient_info] = params[:extra_patient_info].nil? ? false : params[:extra_patient_info]
    @result[:extra_patient_info] = patient.invoice_extra_info if params[:extra_patient_info]=="true"
    @result[:has_patient_invoice_to] = !patient.invoice_to.nil?
    @result[:only_outstanding_invoice] = params[:show_outstanding_invoice]
    if params[:patient_invoice_to].nil? || params[:patient_invoice_to] == "false" || params[:patient_invoice_to] == false
      @result[:invoice_to] = patient.default_invoice_to
    else
      @result[:invoice_to] = patient.invoice_to
    end
    @result[:invoices] = patient.get_invoices(params[:start_date], params[:end_date], params[:show_outstanding_invoice].nil? ? false : params[:show_outstanding_invoice])

    if params[:hide_payment].nil? || params[:hide_payment] == "false" || params[:hide_payment] == false
      @result[:payments] = patient.get_payments(params[:start_date], params[:end_date])
    else
      @result[:payments] = params[:hide_payment] ? [] : patient.get_payments(params[:start_date], params[:end_date])
    end
    return @result
  end

  def delete_cookies
    cookies.delete :pdf_start_date
    cookies.delete :pdf_end_date
    cookies.delete :pdf_show_outstanding_invoice
    cookies.delete :pdf_hide_payment
    cookies.delete :pdf_extra_patient_info
    cookies.delete :pdf_patient_invoice_to
  end

  def get_patient_dates(patient)
    all_dates = []
    filter_arr = params[:filter].nil? ? [] : params[:filter].split(",")

    # *************here
    if (@company.account.note_letter)
      if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
        all_dates = all_dates | patient.treatment_notes.active_treatment_note.group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "treatment_note")
      else
        all_dates = all_dates | patient.treatment_notes.active_treatment_note.where(["created_by_id = ? ", current_user.id]).group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "treatment_note")
      end
    else
      if can? :view_all , TreatmentNote
        all_dates = all_dates | patient.treatment_notes.active_treatment_note.group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "treatment_note")
      else
        if can? :view_own , TreatmentNote
          all_dates = all_dates | patient.treatment_notes.active_treatment_note.where(["created_by_id = ? ", current_user.id]).group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "treatment_note")
        else
          all_dates = []
        end
      end
    end



    all_dates = all_dates | patient.invoices.active_invoice.group_by { |c| c.issue_date.to_date }.keys if (filter_arr.include? "invoice")
    all_dates = all_dates | patient.payments.active_payment.group_by { |c| c.payment_date.to_date }.keys if (filter_arr.include? "payment")
    # all_dates << patient.appointments.group_by { |c| c.created_at.to_date }.keys
    all_dates = all_dates | patient.recalls.active_recall.group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "recall")
    if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
      all_dates = all_dates | patient.letters.active_letter.group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "letter")
    else
      all_dates = all_dates | patient.letters.active_letter.where(["auther_id = ?", current_user.id]).group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "letter")
    end

    all_dates = all_dates | patient.file_attachments.group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "file")
    all_dates = all_dates | patient.communications.group_by { |c| c.created_at.to_date }.keys if (filter_arr.include? "communication")

    all_dates = all_dates | patient.appointments.group_by { |c| c.appnt_date.to_date }.keys if (filter_arr.include? "appointment")

    return all_dates.uniq.sort.reverse
  end

  def set_cookies_dates(next_date = nil, dates_arr)
    Rails.logger.info "+++++++++++++++++++++++++Cookies dates :- #{dates_arr}"
    if next_date.nil?
      cookies[:previous_date] = nil
      cookies[:start_date] = dates_arr.first.try(:to_date)
      cookies[:next_date] = dates_arr.second.try(:to_date)
    else
      cookies[:previous_date] = cookies[:start_date].try(:to_date)
      cookies[:start_date] = cookies[:next_date].try(:to_date)
      cookies[:next_date] = dates_arr[(dates_arr.index(next_date.try(:to_date)))+1].try(:to_date)
    end
  end

  def get_all_data_of_modules_of_patient(c_date = Date.today)
    date_wise_event = {}
    date_wise_event[:event_date] = c_date
    date_wise_event[:appointments] = []
    date_wise_event[:treatment_notes] = []
    date_wise_event[:invoices] = []
    date_wise_event[:payments] = []
    date_wise_event[:recalls] = []
    date_wise_event[:letters] = []
    date_wise_event[:communications] = []
    date_wise_event[:files] = []

#   Converting filter parameters into array
    filter_arr = params[:filter].nil? ? [] : params[:filter].split(",")

#  Getting treatment notes and their count

#     **********here

    if (@company.account.note_letter)
      if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
        treatment_notes = @patient.first.treatment_notes.active_treatment_note.order("created_at desc")
      else
        treatment_notes = @patient.first.treatment_notes.active_treatment_note.order("created_at desc").where(["date(created_at)= ? AND created_by_id = ? ", c_date , current_user.id])
      end
    else
      if can? :view_all , TreatmentNote
        treatment_notes = @patient.first.treatment_notes.active_treatment_note.order("created_at desc").where(["date(created_at)= ? ", c_date])
      else
        if can? :view_own , TreatmentNote
          treatment_notes = @patient.first.treatment_notes.active_treatment_note.order("created_at desc").where(["date(created_at)= ? AND created_by_id = ? ", c_date , current_user.id])
        else
          treatment_notes = []
        end
      end
    end


    cookies[:total_records] = cookies[:total_records] + treatment_notes.length
    if (filter_arr.include? "treatment_note")
      treatment_note_view(treatment_notes, date_wise_event)
    end



#     Getting patient's invoices lists

    invoices = @patient.first.invoices.active_invoice.where(["date(invoices.issue_date) = ?", c_date]).select("invoices.id , invoices.patientid , invoices.number,invoices.practitioner ,  invoices.issue_date , invoices.invoice_amount , invoices.tax")
# cookies[:flag_count] = cookies[:flag_count] + invoices.length
    if (filter_arr.include? "invoice")
      cookies[:total_records] = cookies[:total_records] + invoices.length
      invoices.each do |invoice|
        item = {}
        item[:id] = "0"*(6-invoice.id.to_s.length)+ invoice.id.to_s
        item[:number] = invoice.number
        item[:invoice_date] = invoice.issue_date.strftime("%d %b %Y")
        # item[:patient] = get_patient_name(invoice.patientid)
        practitioner = invoice.user
        item[:practitioner] = practitioner.try(:full_name_with_title) unless practitioner.nil?
        # item[:issue_date] = invoice.issue_date
        item[:tax] = '% .2f'% (invoice.tax.to_f)
        item[:invoice_amount] = '% .2f'% (invoice.invoice_amount.to_f.round(2))
        item[:outstanding_balance] = '% .2f'% (invoice.calculate_outstanding_balance.to_f.round(2))

        security_role_item = {}
        security_role_item[:read] = can? :index, invoice
        security_role_item[:create] = can? :create, invoice
        security_role_item[:modify] = can? :modify, invoice
        security_role_item[:delete] = can? :delete, invoice
        item[:security_role] = security_role_item

        date_wise_event[:invoices] << item
      end
    end

#   Getting patient's payments lists

    payments = @patient.first.payments.active_payment.where(["date(payment_date) = ?", c_date])

# cookies[:flag_count] = cookies[:flag_count] + payments.length
    if (filter_arr.include? "payment")
      cookies[:total_records] = cookies[:total_records] + payments.length
      payments.each do |payment|
        item = {}
        item[:id] = "0"*(6-payment.id.to_s.length)+ payment.id.to_s
        item[:payment_date] = payment.payment_date.strftime("%d %b %Y")
        # item[:payment_date] = payment.payment_date
        item[:total_paid] = '% .2f'% (payment.get_paid_amount).to_f
        item[:invoices_history] = payment.get_invoices_list_applied_payment #payment.deposited_amount_of_invoice

        security_role_item = {}
        security_role_item[:read] = can? :index, payment
        security_role_item[:create] = can? :create, payment
        security_role_item[:modify] = can? :modify, payment
        security_role_item[:delete] = can? :delete, payment
        item[:security_role] = security_role_item
        date_wise_event[:payments] << item
      end
    end

#    Getting Communications list
    communications = @patient.first.communications.where(["date(created_at) = ?", c_date]).order('created_at desc')

# cookies[:flag_count] = cookies[:flag_count] + communications.length
    business_name = @patient.first.company.businesses.head.first.try(:name)
    if (filter_arr.include? "communication")
      cookies[:total_records] = cookies[:total_records] + communications.length
      communications.each do |commn|
        item = {}
        item[:id] = "0"*(6-commn.id.to_s.length)+ commn.id.to_s
        item[:comm_date] = commn.created_at.to_date.strftime("%A,%eth %b %Y")
        item[:comm_time] = commn.created_at.strftime("%e %b %Y,%I:%M%p")
        item[:to] = commn.to
        item[:from] = commn.from
        item[:patient_id] = commn.patient.id
        item[:patient_name] = commn.patient.full_name
        item[:practitioner] = nil  #"test" # change it with appropriate value
        item[:comm_type] = commn.comm_type
        item[:send_status] = commn.send_status
        item[:category] = commn.category
        item[:direction] = commn.direction
        if commn.category.eql?"Invoice"
          item[:msg_subject] = commn.category + "#" + "0"*(6-commn.link_id.to_s.length) + "#{commn.link_id} - " + business_name
        else
          item[:msg_subject] = commn.category + " - " + business_name
        end

        item[:msg] = commn.message
        item[:comm_links] = ""
        security_role_item = {}
        security_role_item[:read] = can? :index, commn
        security_role_item[:show] = can? :show, commn
        item[:security_role] = security_role_item
        date_wise_event[:communications] << item
      end
    end

#   Getting recall lists
    recalls = @patient.first.recalls.active_recall.where(["date(created_at) = ?", c_date])

# cookies[:flag_count] = cookies[:flag_count] + recalls.length
    if (filter_arr.include? "recall")
      cookies[:total_records] = cookies[:total_records] + recalls.length
      recalls.each do |recall|
        item = {}
        item[:id] = recall.id
        item[:recall_on_date] = recall.recall_on_date
        item[:recall_type_name] = recall.recall_type.try(:name)
        item[:note] = recall.notes
        item[:is_selected] = recall.is_selected
        item[:recall_set_date] = recall.recall_set_date.nil? ? nil : recall.recall_set_date.strftime("%d %b %Y")
        item[:created_by_user] = recall.find_owner
        security_role_item = {}
        security_role_item[:read] = can? :index, Recall
        security_role_item[:create] = can? :create, Recall
        security_role_item[:modify] = can? :edit, Recall
        security_role_item[:delete] = can? :destroy, Recall
        security_role_item[:check_option] = can? :set_recall_set_date , Recall
        item[:security_role] = security_role_item
        date_wise_event[:recalls] << item
      end
    end

#   Getting appointment lists

    appointments = @patient.first.appointments.active_appointment.where(["date(appnt_date) = ?", c_date])

# cookies[:flag_count] = cookies[:flag_count] + recalls.length
    if (filter_arr.include? "appointment")
      cookies[:total_records] = cookies[:total_records] + appointments.length
      appointments.each do |appointment|
        item = {}
        item[:id] = appointment.id
        apnt_date = appointment.appnt_date.to_date.strftime("%A,%d %B %Y")
        apnt_start_time = appointment.appnt_time_start.strftime(" at %H:%M%p")
        item[:appnt_date] = apnt_date + apnt_start_time
        item[:patient_status] = appointment.patient_arrive
        item[:appointment_type_name] = appointment.appointment_type.try(:name)
        item[:appointment_type_color] = appointment.appointment_type.try(:color_code)
        item[:practitioner] = appointment.user.try(:full_name)
        item[:is_cancel] = !(appointment.try(:cancellation_time).nil?)

        security_role_item = {}
        security_role_item[:manage] = can? :manage, appointment
        item[:security_role] = security_role_item
        date_wise_event[:appointments] << item
      end
    end

#   Getting letter lists
    if (@company.account.note_letter)
      if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
        letters = @patient.first.letters.active_letter
      else
        letters = @patient.first.letters.active_letter.where(["auther_id = ? ", current_user.id])
      end
    else
      if can? :manage_own , Letter
        if can? :manage_all , Letter
          letters = @patient.first.letters.active_letter.where(["date(created_at)= ? ", c_date])
        else
          letters = @patient.first.letters.active_letter.where(["auther_id = ? AND date(created_at)= ? ", current_user.id , c_date])
        end
      else
        if can? :manage_all , Letter
          letters = @patient.first.letters.active_letter.where(["date(created_at)= ? ", c_date])
        else
          letters = []
        end
      end
    end
#     if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter)) || current_user.role.casecmp("administrator") == 0
#       letters = @patient.first.letters.active_letter.where(["date(created_at) = ?", c_date])
#     else
#       letters = @patient.first.letters.active_letter.where(["date(created_at) = ? and auther_id = ? ", c_date, current_user.id])
#     end


# cookies[:flag_count] = cookies[:flag_count] + letters.length
    if (filter_arr.include? "letter")
      cookies[:total_records] = cookies[:total_records] + letters.length
      letters.each do |letter|
        item = {}
        item[:id] = letter.id
        item[:description] = letter.description
        item[:content] = letter.content

#       security role of logged in to access treatment note
        security_role_item = {}
        security_role_item[:send_email] = ((can? :manage_own, Letter) || (can? :manage_all, Letter))
        security_role_item[:print] = ((can? :manage_own, Letter) || (can? :manage_all, Letter))
        security_role_item[:download] = ((can? :manage_own, Letter) || (can? :manage_all, Letter))
        if (can? :manage_all, Letter)
          security_role_item[:modify] = true
        else
          security_role_item[:modify] = (can? :manage_own, Letter)
        end

        security_role_item[:delete] = can? :destroy ,  Letter

        item[:security_role] = security_role_item

# item[:created_by] = User.find(letter.auther_id).full_name_with_title
        date_wise_event[:letters] << item
      end
    end
#     Getting files lists

    files = @patient.first.file_attachments.order("created_at desc").where(["date(created_at) = ?", c_date])
    account = @company.account
# cookies[:flag_count] = cookies[:flag_count] + files.length
    if (filter_arr.include? "file")
      cookies[:total_records] = cookies[:total_records] + files.length
      files.each do |attach_file|
        item = {}
        item[:id] = attach_file.id
        item[:name] = attach_file.avatar.original_filename
        item[:type] = attached_file_type(attach_file)
        item[:description] = attach_file.description.nil? ? "" : attach_file.description
        item[:created_on] = attach_file.created_at.strftime("%d %b %Y")
        item[:file_size] = number_to_human_size(attach_file.avatar.size)
        item[:file_url] = attach_file.avatar.try(:url)
        item[:created_by] = attach_file.find_uploader

        if (!(account.show_attachment) && (current_user.try(:user_role).try(:name).eql?(ROLE[1] || current_user.try(:user_role).try(:name).eql?(ROLE[4]))))
          item[:has_permission] = false
        else
          item[:has_permission] = true
        end
        security_role_item = {}
        security_role_item[:upload] = (can? :upload, attach_file)
        security_role_item[:modify] = can? :edit, attach_file
        if can? :delall , FileAttachment
          security_role_item[:delete] = true
        else
          if can? :delown , FileAttachment
            security_role_item[:delete] = (attach_file.created_by.to_s == current_user.id.to_s)
          else
            security_role_item[:delete] = false
          end
        end


        security_role_item[:view_name] = can? :viewname, attach_file
        security_role_item[:clickable_link] = can? :viewfile, attach_file
        security_role_item[:role] = current_user.role

        item[:security_role] = security_role_item
        date_wise_event[:files] << item
      end
    end
#    Checking date wise item
    date_wise_items_count = date_wise_event[:appointments].length + date_wise_event[:treatment_notes].length + date_wise_event[:invoices].length + date_wise_event[:payments].length + date_wise_event[:recalls].length + date_wise_event[:communications].length + date_wise_event[:files].length + date_wise_event[:letters].length
    return date_wise_items_count > 0 ? date_wise_event : nil
  end


  def set_relation(patient, params)
    params[:patient][:relationship].each do |rs|
      unless rs[:patient].nil?
        main_item = {}
        item = {}
        item[:id] = rs[:patient][:id]
        item[:first_name] = rs[:patient][:first_name]
        item[:last_name] = rs[:patient][:last_name]
        main_item[:patient] = item
        main_item[:type] = rs[:type]
        patient.relationship << main_item
      end
    end unless params[:patient][:relationship].nil?
  end

  def set_patient_format(patient)
    result = {}
    result[:id] = patient.id
    result[:title] = patient.title
    result[:first_name] = patient.first_name
    result[:last_name] = patient.last_name
    result[:gender] = patient.gender
    result[:logo] = patient.profile_pic
    result[:logo_flag] = (patient.profile_pic.url.include?'http') ? true : false
    result[:relationship] = patient.relationship
    result[:enate_id] = patient.enate_id.present? ? patient.enate_id : false
    result[:patient_contacts_attributes] = []
    patient.patient_contacts.each do |contact|
      item = {}
      item[:id] = contact.id
      item[:contact_no] = (contact.contact_no.nil? ? contact.contact_no : contact.contact_no.phony_formatted(format: :international, spaces: '-'))
      item[:contact_type] = contact.contact_type
      result[:patient_contacts_attributes] << item
    end
    result[:email] = patient.email
    result[:primary_no] = patient.get_primary_contact
    result[:reminder_type] = ([nil, "none", "None"].include?(patient.reminder_type)) ? "none" : patient.reminder_type.downcase
    result[:sms_marketing] = (patient.sms_marketing)
    result[:address] = patient.address
    result[:country] = patient.country
    result[:state] = patient.state
    result[:city] = patient.city
    result[:postal_code] = patient.postal_code
    result[:concession_type] = patient.concession.try(:id).to_s
    result[:concession_name] = patient.concession.try(:name).to_s
    result[:invoice_email] = patient.invoice_email
    result[:invoice_to] = patient.invoice_to
    result[:invoice_extra_info] = patient.invoice_extra_info
    result[:occupation] = patient.occupation
    result[:emergency_contact] = patient.emergency_contact
    result[:medicare_number] = patient.medicare_number
    result[:reference_number] = patient.reference_number
    unless patient.contact.nil?
      item = {}
      item[:id] = patient.patients_contact.try(:id)
      item[:contact_id] = patient.contact.try(:id)
      item[:first_name] = patient.contact.try(:first_name)
      item[:last_name] = patient.contact.try(:last_name)
    end
    result[:refer_doctor] = item
    result[:notes] = patient.notes
    result[:referral_type] = patient.referral_type
    result[:referrer] = patient.referrer #["first_name"] + patient.referrer["last_name"]
    result[:extra_info] = patient.extra_info
    result[:status] = patient.status
    result[:updated_at] = patient.updated_at
    result[:age] = patient.age
    result[:dob] = patient.dob
    next_appointment = patient.next_appointment
    unless next_appointment.nil?
      item = {}
      item[:appointment_id] = next_appointment.id
      item[:appointment_name] = next_appointment.date_and_time_without_name
      item[:appointment_date] = next_appointment.appnt_date
      item[:appointment_time] = next_appointment.appnt_time_start
      item[:practitioner_name] = next_appointment.user.full_name_with_title
      result[:next_appointment_info] = item
    else
      result[:next_appointment_info] = nil
    end
    result[:outstanding_balance] = patient.calculate_patient_outstanding_balance
    result[:credit_amount] = patient.calculate_patient_credit_amount

#     Adding filter for client page 
    result[:filter] = {appointment: current_user.client_filter_choice.appointment, treatment_note: current_user.client_filter_choice.treatment_note, invoice: current_user.client_filter_choice.invoice, payment: current_user.client_filter_choice.payment, recall: current_user.client_filter_choice.recall, file: current_user.client_filter_choice.attached_file, letter: current_user.client_filter_choice.letter, communication: current_user.client_filter_choice.communication}

    return result
  end


  #  adding _destroy:true into params for deleting record      
  def add_destory_key_to_params(params, patient)
    all_patient_contacts_ids = patient.patient_contacts.pluck("id")
    unless params[:patient][:patient_contacts_attributes].nil?
      patient_contacts_ids = params[:patient][:patient_contacts_attributes].map { |k| k["id"] }
      patient_contacts_deleteable = all_patient_contacts_ids - patient_contacts_ids
    else
      params[:patient][:patient_contacts_attributes] = []
      patient_contacts_deleteable = all_patient_contacts_ids
    end

    patient_contacts_deleteable.each do |id|
      patient_contact = PatientContact.find(id)
      patient_contact_item = {}
      patient_contact_item[:id] = patient_contact.id
      patient_contact_item[:contact_no] = patient_contact.contact_no.phony_formatted(format: :international, spaces: '-')
      patient_contact_item[:contact_type] = patient_contact.contact_type
      patient_contact_item[:_destroy] = true
      params[:patient][:patient_contacts_attributes] << patient_contact_item
    end
  end

  #     Over here

  def set_blank_patient_contact(params)
    all_contacts = params[:patient][:patient_contacts_attributes]
    unless all_contacts.nil?
      all_contacts.each do |item|
        if item["contact_no"].blank?
          params[:patient][:patient_contacts_attributes].delete(item)
        end
      end
    end

  end

  def Add_custom_error_msg(patient)
    unless patient.errors.messages[:"patient_contacts.contact_no"].nil?
      patient.errors.messages.delete(:"patient_contacts.contact_no")
      patient.errors.add(:Phone_number, "is Invalid")
    end
  end

  def Add_custom_error_zip_msg(patient)
    unless patient.errors.messages[:"postal_code"].nil?
      patient.errors.messages.delete(:"postal_code")
      patient.errors.add(:Postal_code, "is Invalid")
    end
  end


  def set_client_filters_for_current_user(filter, user)
    filter_model = user.client_filter_choice
    filter_model = user.create_client_filter_choice() if filter_model.nil?
    filter_model.update_attributes(appointment: false, invoice: false, payment: false, attached_file: false, letter: false, communication: false, recall: false, treatment_note: false)
    filter.each do |filter_attr|
      unless (filter_attr <=> "file") == 0
        filter_model.update_attributes(filter_attr.to_sym => true)
      else
        filter_model.update_attributes(:attached_file => true)
      end
    end

  end

  def make_dynamic_sms_content(content, receiver_id, obj_type, doctor_id=nil, bs_id=nil, contact_id=nil)
    patient = Patient.find_by_id(receiver_id) unless receiver_id.nil?
    doctor = SmsLog.doctor(doctor_id) unless doctor_id.nil?
    contact = Contact.find_by_id(contact_id) unless contact_id.nil?
    loc = Business.find_by_id(bs_id) unless bs_id.nil?

    refer_doc = patient.contact

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

end
	