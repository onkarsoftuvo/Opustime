class Admin::AdminPatientsController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  before_action :find_company , :only =>[:index , :create , :doctors_list , :referral_list , :list_related_patients , :list_contact , :account_statement , :account_history , :clients_modules, :account_statement_pdf , :send_email , :get_patient_submodules_total ]
  before_action :find_patient , :only => [:edit , :update , :destroy , :show , :permanent_delete , :status_active , :account_statement , :account_history , :clients_modules , :send_email , :get_patient_submodules_total, :account_statement_pdf , :identical  , :patient_merge , :has_patient_wait_list ]
  before_action :set_params_in_format, :only => [:create,:update] 
  #load_and_authorize_resource
  
  def edit
    unless @patient.nil?
    patient =  @patient.specific_attributes.first
    result  = set_patient_format(patient) 
    end
    render :json=> result  
  end
  
  def update
    if  params[:patient].keys.include?"comming_from"
      @patient = Patient.find(params[:id])
      @patient.update_attributes(patients_params)
      if @patient.save
        respond_to do |format|
          #flash[:success] = "User was successfully updated."
          format.html { redirect_to  "/business/#{@patient.id}/edit_patient", notice: 'Patient was successfully updated.' }
        end
      else
        respond_to do |format|
          #flash[:success] = "User was successfully updated."
          custom_err_msg =  @patient.errors.messages.keys.first.to_s
          format.html { redirect_to  "/business/#{@patient.id}/edit_patient", alert: custom_err_msg  + " " + 'should be valid format'}
        end
      end 
    else
      unless @patient.nil?
      patient = @patient.first 
      #  calling method to add _destroy params in deleted items
      set_blank_patient_contact(params)     
      add_destory_key_to_params(params , patient)
      patient.update_attributes(patients_params)
      if patient.valid?

  #     To update relationship records since it's unpermitted   
        patient.relationship = []
        set_relation(patient , params)

        patient.save
         
        result = {flag: true }
        render :json=> result
      else
        Add_custom_error_msg(patient)
        show_error_json(patient.errors.messages)
      end
      else
        result = {flag: false }
       render :json=> result
      end
    end 
  end
  
  def status_active
    unless @patient.nil?
    patient = @patient.first
    patient.update_attributes(:status=> STATUS[1])
    if patient.valid?
      result = {flag: true  }
      render :json=> result
    else 
      show_error_json(patient.errors.messages)
    end
    else
      result = {flag: false }
      render :json=> result
    end
  end
  
  def doctors_list
    doctors = @company.contacts.where(contact_type: "Doctor" , status: true).select("id , first_name , last_name")
    render :json=> doctors
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
    render :json=> patient_list
  end
  
  def list_contact
    referral = @company.contacts.select("id , first_name , last_name")
    render :json=> referral 
  end
#   Patient 's account statement info 
  def account_statement
    result = {}
    save_filter_params_into_cookies(params)  # saving filter params into cookies for pdf
    patient = @patient.first
    business = @company.businesses.head.first
    patient.get_business_detail_info(result , business)
    result[:filter_from] = (params[:start_date].nil? ? params[:start_date] : params[:start_date].to_date.strftime("%d %b %Y"))   
    result[:filter_to] = (params[:end_date].nil? ? params[:end_date] : params[:end_date].to_date.strftime("%d %b %Y"))
    result[:patient_outstanding_balance] = patient.calculate_patient_outstanding_balance(params[:start_date] ,  params[:end_date])
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
    result[:invoices] = patient.get_invoices(params[:start_date] , params[:end_date], params[:show_outstanding_invoice].nil? ? false : params[:show_outstanding_invoice])
    if params[:hide_payment].nil?
      result[:payments] = patient.get_payments(params[:start_date] , params[:end_date])        
    else
      result[:payments] = params[:hide_payment] ? [] :  patient.get_payments(params[:start_date] , params[:end_date]) 
    end
    render :json=> result
  end
#   Display account statement in pdf 
  def account_statement_pdf
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
        render :pdf => "pdf_name.pdf" , 
               :layout => '/layouts/pdf.html.erb' ,
               :disposition => 'inline' ,
               :template    => "/patients/account_statement_pdf.pdf.erb",
               :show_as_html => params[:debug].present? ,
               :footer=> { right: '[page] of [topage]' }
      end
    end
  end
  
#   To get identical patients for merge
  def identical
    result = [] 
    unless @patient.nil?
      patient = @patient.first
      company = patient.company
      identical_patients = company.patients.active_patient.where('lower(first_name) = ? AND lower(last_name) = ? AND id != ? ', patient.first_name.downcase , patient.last_name.downcase , patient.id ).select("id , first_name , last_name , dob , created_at ")
      identical_patients.each do |similar_patient|
        item = {}
        item[:id] = similar_patient.id
        item[:name] = similar_patient.first_name.to_s + " " + similar_patient.last_name.to_s  
        item[:mobile_no] = similar_patient.patient_contacts.length == 0 ? nil : similar_patient.patient_contacts.where(contact_type: "mobile").first.contact_no
        item[:dob] = similar_patient.dob.strftime("%d %b %Y") rescue nil   
        item[:created] = similar_patient.created_at.strftime("%d %b %Y")
        result << item
      end
    end 
    render :json=> {identical_patients: result} 
     
  end
  
#   Functionality to merge existing one patient. 
  def patient_merge
    unless @patient.nil?
    TreatmentNote.current = current_user
    sm_patients = Patient.active_patient.where("id IN (?)", params[:identical_patients])
    sm_patients.each do |ptnt|
      invoices = ptnt.invoices
      @patient.first.invoices << ptnt.invoices
      @patient.first.payments << ptnt.payments 
      @patient.first.patient_contacts << ptnt.patient_contacts
      @patient.first.medical_alerts << ptnt.medical_alerts
      @patient.first.treatment_notes << ptnt.treatment_notes
      @patient.first.communications << ptnt.communications
      @patient.first.recalls << ptnt.recalls
      @patient.first.letters << ptnt.letters
      # Shifting file attachments 
      ptnt.file_attachments.each do |attach_file|
        @patient.first.file_attachments.create(:avatar=> attach_file.avatar ) if attach_file.avatar.exists?
        attach_file.destroy    
      end
      ptnt.update_attributes(status: false)
    end
    render :json=> {flag: true}
    else
      render :json=>{flag: false} 
    end
  end
#   To patient's account history 
  def account_history
    @result = {}
    unless @patient.nil?
      patient = @patient.first
      @result[:patient_name] = patient.full_name
      @result[:dob] = patient.dob.strftime("%d %b %Y")
      @result[:occupation] = patient.occupation
      @result[:medicare_no] = patient.medicare_number
      @result[:appointments] = []
      @result[:treatment_notes] = []
  #     Getting treatment notes to view in pdf
      treatment_notes = @patient.first.treatment_notes.active_treatment_note.order("created_at desc")
      treatment_note_view(treatment_notes , @result )
      @business_head  = @company.businesses.head.first.try(:name)
      respond_to do |format|
        format.html
        format.pdf do
          render :pdf => "pdf_name.pdf" , 
                 :layout => '/layouts/pdf.html.erb' ,
                 :disposition => 'inline' ,
                 :template    => "/patients/account_history.pdf.erb",
                 :show_as_html => params[:debug].present? ,
                 :footer =>  { html: {   template:'/patients/history_report_footer.pdf.erb', # use :template OR :url
                                            locals:  { location: @business_head }},
                              line:              true,
                              spacing:           10,
                              left: '[page] of [topage]'
                              }
        end
      end
    else
      render :json=> {patient: result}
    end
  end
#   Getting listing of every submodules dates wise on client show page 
  def clients_modules
    result = []
    unless @patient.nil?
  #   checking authority for filter for current user so that anyone can not make hit with extra parameters  
      check_authority_for_filter(params)
      
  #    Applying filter choice  for current user
      unless params[:filter].nil? 
        set_client_filters_for_current_user(params[:filter].split(",") , current_user) unless  (params[:filter].split(",") - ["appointment", "treatment_note","invoice", "payment","recall" , "letter", "file","communication"]).length > 0   
      end 
      cookies.delete :date if params[:page].nil?
      cookies[:date] = get_patient_dates(@patient.first) if cookies[:date].nil? 
  #   local storage to check - is there any data available for a particular date 
      cookies[:total_records] = 0
  
  #   Getting data datewise minimum 10 and it will take all records for a particular date weather it is crossing 10 or not  
      if cookies[:date].length > 0
  #       Checking pagination hit having next_date or not
        if params[:next_date].nil?
          set_cookies_dates(nil , cookies[:date])
          result << get_all_data_of_modules_of_patient(cookies[:start_date])
        else
          cookies[:date]= cookies[:date].split("&").map{|k|k.to_date}
          set_cookies_dates(params[:next_date] , cookies[:date])
          result << get_all_data_of_modules_of_patient(params[:next_date].to_date)
        end
        while (cookies[:total_records] < CLIENT_EVENT_SIZE && !(cookies[:next_date].try(:to_date).nil?) )#((cookies[:total_records] < CLIENT_EVENT_SIZE) ) && (cookies[:flag_count] >  0 && !(cookies[:next_date].try(:to_date).nil?) )  do
          set_cookies_dates(cookies[:next_date].try(:to_date) , cookies[:date])
          result <<  get_all_data_of_modules_of_patient(cookies[:start_date].to_date)
        end 
      end
  #   Adding next url hit with data for pagination purpose 
      params_query_str = cookies[:next_date].blank?  ? nil : "?next_date=#{cookies[:next_date].to_date.strftime('%d-%b-%Y')}&page=#{params[:page].to_i + 1}&filter=#{params[:filter]}"
      main_result = {next_hit: (!(params_query_str.nil?) ? "#{root_url}patients/#{params[:id]}/client_profile"+params_query_str : nil) ,  modules: result.compact}
      
      render :json => main_result
    else
      render :json=>{patient: result}
    end
  end
#   To get the counting of every sub-modules to display on client page 
  def get_patient_submodules_total
    result = {}
    unless @patient.nil?
      patient = @patient.first
      if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter))  || current_user.role.casecmp("administrator") == 0
        result[:treatment_notes_count] = patient.treatment_notes.active_treatment_note.count  
      end
      
      result[:invoices_count] = patient.invoices.active_invoice.count
      result[:payments_count] = patient.payments.active_payment.count
      result[:recalls_count] = patient.recalls.active_recall.count
      if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter))  || current_user.role.casecmp("administrator") == 0
        result[:letters_count] = patient.letters.active_letter.count  
      else
        result[:letters_count] = patient.letters.active_letter.where(["auther_id = ? " , current_user.id]).count
      end
      
      result[:communications_count] = patient.communications.count
      result[:files_count] = patient.file_attachments.count
      result[:appointments_count] = patient.appointments.active_appointment.count
      render :json=> result
    else
      render :json=> {patient: result}
    end 
  end 
#   To send email to patient or other 
  def send_email
    unless @patient.nil?
      fetch_filter_from_cookies_to_params(params) # getting filter params from cookies for pdf
      @result = get_account_statement_data
      
      html = render_to_string(:action => :account_statement_pdf, :layout => "/layouts/pdf.html.erb", :formats => [:pdf] , :locals=>{:@result=> @result}) 
      pdf = WickedPdf.new.pdf_from_string(html) 
      @patient_info = @patient.first
      @business = @patient_info.company.businesses.head.first
      flag = params[:email_to].to_s.casecmp("patient") == 0 ? true : false
      greeting_text = flag ? "Hi #{@patient_info.first_name.capitalize}" : "hello"
      comm_msg = "<p> #{greeting_text}, </p><p> Attached is your Account Statement from #{flag ? @patient_info.full_name : @business.name }  </p><p> Thank you </p><p>#{@business.name}</p>"
      communication = @patient_info.communications.build(comm_time: Time.now , comm_type: "email", category: "Account Statement", direction: "sent", to: @patient_info.email , from: @patient_info.company.communication_email , message: comm_msg , send_status: true )
      if communication.valid?
        communication.save
        begin
          PatientMailer.account_statement_email(@patient_info, params[:email_to], current_user , pdf).deliver_now   
        rescue Exception=> e
          puts e.message        
        end
        result = {flag: true}
        render :json=> result
      else
        show_error_json(communication.errors.messages)
      end
    else
      result = {flag: false}
      render :json=> result
    end
  end
  
  def user_role_wise_authority  
    result = {}
    patient = Patient.first
    
#   patient details security role 
    result[:read] = can? :read , patient
    result[:modify] =  can? :modify , patient
    result[:merge] =  can? :merge , patient  
    result[:history_report] = can? :account_history , patient
    result[:account_statement] = can? :account_statement , patient
    result[:archive_or_activate] = can? :delete , patient
    result[:delete] = can? :delete_parmanent , patient
#   security role for sub-modules show/hide on client module  
    result[:treatment_note] = can? :read  , TreatmentNote.first
    result[:letter] = can? :read  , Letter.first
    result[:invoice] = can? :read  , Invoice.first
    result[:payment] = can? :read  , Payment.first
    result[:recall] = can? :read  , Recall.first
    result[:file_attachment] = can? :upload , FileAttachment.first
    result[:communication] =  can? :read , Communication.first  
    result[:appointment] =  true   # it has to be changed later 
        
    render :json => {result: result , role: current_user.role } 
  end
  
  def check_authority_for_filter(params)
     a = params[:filter].nil? ? [] : params[:filter].split(",").collect(&:strip)  
     unless can? :read  , TreatmentNote.first
       a.delete("treatment_note")
     end
     unless can? :read  , Letter.first
       a.delete("letter")
     end
     unless can? :read  , Invoice.first
       a.delete("invoice")
     end
     unless can? :read  , Payment.first
       a.delete("payment")
     end
     unless can? :read  , Recall.first
       a.delete("recall")
     end
     unless can? :upload  , FileAttachment.first
       a.delete("file")
     end
     unless can? :read  , Communication.first
       a.delete("communication")
     end
     params[:filter] =  a.join(",")
  end
  
  def has_patient_wait_list
    unless @patinet.nil?
    patient = @patient.first
    result = {flag: false}
    unless patient.nil?
      if patient.wait_list.try(:status) == true
        result = {flag: true , patient_id: patient.id ,  patient_name: patient.full_name , wait_list_id: patient.wait_list.id }
      end
    end
    render :json=> result
    else
      render :json=> {patinet: result}
    end
  end
  
  
  private
  
  def patients_params                                                                                                                                                             
    params.require(:patient).permit(:id , :title, :first_name, :last_name, :dob, :gender, {relationship: []} , :email, :reminder_type, :sms_marketing, :address, :country, :state, :city, :postal_code, :concession_type, :invoice_to, :invoice_email, :invoice_extra_info, :occupation, :emergency_contact, :medicare_number, :reference_number, :refer_doctor, :notes, :referral_type, :referrer, :extra_info , :status,
    {:concessions_patient_attributes => [:id,:concession_id, :_destroy]},
    {:patients_contact_attributes=> [:id, :contact_id, :_destroy]},
    {:patient_contacts_attributes=>[:id, :contact_no , :contact_type , :_destroy]}).tap do |whitelisted|
      whitelisted[:referrer] = params[:patient][:referrer]  unless params[:patient][:referrer].nil?

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
   
   #managing concession
      params[:patient][:concessions_patient_attributes] = {}
      item = {}
      cs_id = params[:patient][:concession_type].to_i 
      
      if cs_id > 0
        if params[:action] == "update"
          unless cs_id == @patient.first.concession.try(:id)
            item[:concession_id] = cs_id
            params[:patient][:concessions_patient_attributes] = item
          else
            record = ConcessionsPatient.where(["patient_id =? AND concession_id=? ",@patient.first.id,cs_id ]).first
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
            record = ConcessionsPatient.where(["patient_id =? AND concession_id=? ",@patient.first.id, @patient.first.concession.id]).first
            item[:id] = record.try(:id)
            item[:_destroy] = true
            params[:patient][:concessions_patient_attributes] = item  
          end
          
        end
      end
  end
    
 def find_patient
    company = Company.find_by_id(session[:comp_id])
    if company.nil?
      @patient = nil
    else
      @patient = company.patients.where(["patients.id = ?",params[:id]]).active_patient
    end
    return @patient
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
    
    params[:start_date] = cookies[:pdf_start_date].blank? ? nil :  cookies[:pdf_start_date]
    params[:end_date] = cookies[:pdf_end_date].blank? ? nil :  cookies[:pdf_end_date] 
    params[:show_outstanding_invoice] = cookies[:pdf_show_outstanding_invoice].blank? ? nil :  cookies[:pdf_show_outstanding_invoice].to_bool 
    params[:hide_payment] = cookies[:pdf_hide_payment].blank? ? nil :  cookies[:pdf_hide_payment].to_bool  
    params[:extra_patient_info] = cookies[:pdf_extra_patient_info].blank? ? nil :  cookies[:pdf_extra_patient_info].to_bool  
    params[:patient_invoice_to] = cookies[:pdf_patient_invoice_to].blank? ? nil :  cookies[:pdf_patient_invoice_to].to_bool  
  end
  
  def get_account_statement_data
    @result = {}
    patient = @patient.first
    business = @company.businesses.head.first
    patient.get_business_detail_info(@result , business)
    @result[:filter_from] = ((params[:start_date].nil? || params[:start_date].blank?) ? params[:start_date] : params[:start_date].to_date.strftime("%d %b %Y"))   
    @result[:filter_to] = ((params[:end_date].nil? || params[:end_date].blank?) ? params[:end_date] : params[:end_date].to_date.strftime("%d %b %Y"))
    @result[:patient_outstanding_balance] = patient.calculate_patient_outstanding_balance(params[:start_date] ,  params[:end_date])
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
    @result[:invoices] = patient.get_invoices(params[:start_date] , params[:end_date], params[:show_outstanding_invoice].nil? ? false : params[:show_outstanding_invoice])
    
    if params[:hide_payment].nil? || params[:hide_payment] == "false" || params[:hide_payment] == false
      @result[:payments] = patient.get_payments(params[:start_date] , params[:end_date])        
    else
      @result[:payments] = params[:hide_payment] ? [] :  patient.get_payments(params[:start_date] , params[:end_date]) 
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
    filter_arr =    params[:filter].nil? ? [] :  params[:filter].split(",")
    if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter))  || current_user.role.casecmp("administrator") == 0
      all_dates = all_dates | patient.treatment_notes.active_treatment_note.group_by { |c| c.created_at.to_date }.keys   if (filter_arr.include?"treatment_note")      
    end
      
    all_dates = all_dates | patient.invoices.active_invoice.group_by { |c| c.issue_date.to_date }.keys  if (filter_arr.include?"invoice")
    all_dates = all_dates | patient.payments.active_payment.group_by { |c| c.payment_date.to_date }.keys if (filter_arr.include?"payment")
    # all_dates << patient.appointments.group_by { |c| c.created_at.to_date }.keys
    all_dates = all_dates | patient.recalls.active_recall.group_by { |c| c.created_at.to_date }.keys  if (filter_arr.include?"recall")
    if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter))  || current_user.role.casecmp("administrator") == 0
      all_dates = all_dates | patient.letters.active_letter.group_by { |c| c.created_at.to_date }.keys if (filter_arr.include?"letter")  
    else
      all_dates = all_dates | patient.letters.active_letter.where(["auther_id = ?" , current_user.id]).group_by { |c| c.created_at.to_date }.keys  if (filter_arr.include?"letter")
    end
    
    all_dates = all_dates | patient.file_attachments.group_by { |c| c.created_at.to_date }.keys  if (filter_arr.include?"file")
    all_dates = all_dates | patient.communications.group_by { |c| c.created_at.to_date }.keys if (filter_arr.include?"communication")
    
    all_dates = all_dates | patient.appointments.group_by { |c| c.appnt_date.to_date }.keys if (filter_arr.include?"appointment")
    
    return all_dates.uniq.sort.reverse
  end
  
  def set_cookies_dates(next_date = nil, dates_arr)
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
    filter_arr =    params[:filter].nil? ? [] :  params[:filter].split(",")  
#     Getting treatment notes and their count
    if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter))  || current_user.role.casecmp("administrator") == 0
      treatment_notes = @patient.first.treatment_notes.active_treatment_note.order("created_at desc").where(["date(created_at)= ? " , c_date])      
     
      # treatment_notes = @patient.first.treatment_notes.active_treatment_note.order("created_at desc").where(["date(created_at)= ? " , c_date])
      cookies[:total_records] = cookies[:total_records] + treatment_notes.length
      # cookies[:flag_count] = cookies[:flag_count] + treatment_notes.length
      if (filter_arr.include?"treatment_note")
        treatment_note_view(treatment_notes , date_wise_event )   
      end
    end
#     Getting patient's invoices lists
    
    invoices =  @patient.first.invoices.active_invoice.where(["date(invoices.issue_date) = ?",c_date]).select("invoices.id , invoices.patientid , invoices.practitioner ,  invoices.issue_date , invoices.invoice_amount , invoices.tax")
    cookies[:total_records] = cookies[:total_records] + invoices.length
    # cookies[:flag_count] = cookies[:flag_count] + invoices.length 
    if (filter_arr.include?"invoice")  
      invoices.each do |invoice|
        item = {}
        item[:id] = "0"*(6-invoice.id.to_s.length)+ invoice.id.to_s 
        item[:invoice_date] = invoice.issue_date.strftime("%d %b %Y")    
        # item[:patient] = get_patient_name(invoice.patientid)
        practitioner = invoice.user 
        item[:practitioner] = practitioner.try(:full_name_with_title) unless practitioner.nil?  
        # item[:issue_date] = invoice.issue_date
        item[:tax] = invoice.tax.to_f
        item[:invoice_amount] = invoice.invoice_amount.to_f.round(2)
        item[:outstanding_balance] = invoice.calculate_outstanding_balance.to_f.round(2)
        
        security_role_item = {}
        security_role_item[:read] = can? :read , invoice
        security_role_item[:create] = can? :create , invoice
        security_role_item[:modify] = can? :modify , invoice
        security_role_item[:delete] = can? :delete , invoice 
        item[:security_role] = security_role_item
        
        date_wise_event[:invoices] << item 
      end
    end

#   Getting patient's payments lists
    
    payments = @patient.first.payments.active_payment.where(["date(payment_date) = ?" , c_date])
    cookies[:total_records] = cookies[:total_records] + payments.length
    # cookies[:flag_count] = cookies[:flag_count] + payments.length 
    if (filter_arr.include?"payment") 
      payments.each do |payment|
        item = {}
        item[:id] = "0"*(6-payment.id.to_s.length)+ payment.id.to_s 
        item[:payment_date] = payment.payment_date.strftime("%d %b %Y") 
         # item[:payment_date] = payment.payment_date
        item[:total_paid] = payment.get_paid_amount
        item[:invoices_history] = payment.get_invoices_list_applied_payment #payment.deposited_amount_of_invoice

        security_role_item = {}
        security_role_item[:read] = can? :read , payment
        security_role_item[:create] = can? :create , payment
        security_role_item[:modify] = can? :modify , payment
        security_role_item[:delete] = can? :delete , payment 
        item[:security_role] = security_role_item
        date_wise_event[:payments] << item
      end 
    end
    
#    Getting Communications list
    communications = @patient.first.communications.where(["date(created_at) = ?" , c_date])
    cookies[:total_records] = cookies[:total_records] + communications.length 
    # cookies[:flag_count] = cookies[:flag_count] + communications.length 
    business_name = @patient.first.company.businesses.head.first.name
    if (filter_arr.include?"communication")
      communications.each do |commn|
        item = {}
        item[:id] =  "0"*(6-commn.id.to_s.length)+ commn.id.to_s
        item[:comm_date] = commn.created_at.to_date.strftime("%A,%eth %b %Y")
        item[:comm_time] = commn.created_at.strftime("%e %b %Y,%I:%M%p")
        item[:to] = commn.to
        item[:from] = commn.from
        item[:patient_id] = commn.patient.id
        item[:patient_name] = commn.patient.full_name
        item[:practitioner] = "test" # change it with appropriate value
        item[:comm_type] = commn.comm_type
        item[:send_status] = commn.send_status
        item[:category] = commn.category
        item[:direction] = commn.direction
        item[:msg_subject] =  commn.category + " - " + business_name
        item[:msg] = commn.message
        item[:comm_links] = "" 
        security_role_item = {}
        security_role_item[:read] = can? :read , commn
        security_role_item[:show] = can? :show , commn
        item[:security_role] = security_role_item
        date_wise_event[:communications] << item 
      end
    end

#   Getting recall lists 
    recalls = @patient.first.recalls.active_recall.where(["date(created_at) = ?" , c_date]) 
    cookies[:total_records] = cookies[:total_records] + recalls.length
    # cookies[:flag_count] = cookies[:flag_count] + recalls.length
    if (filter_arr.include?"recall")
      recalls.each do |recall|
        item = {}
        item[:id] = recall.id
        item[:recall_on_date] = recall.recall_on_date
        item[:recall_type_name] = recall.recall_type.name
        item[:note] = recall.notes
        item[:is_selected] = recall.is_selected
        item[:recall_set_date] = recall.recall_set_date.nil? ? nil : recall.recall_set_date.strftime("%d %b %Y") 
        item[:created_by_user] = User.find(recall.created_by_id).try(:full_name)
        security_role_item = {}
        security_role_item[:read] = can? :read , recall
        security_role_item[:create] = can? :create , recall
        security_role_item[:modify] = can? :read , recall
        security_role_item[:delete] = can? :delete , recall
        item[:security_role] = security_role_item 
        date_wise_event[:recalls] << item 
      end
    end
    
    #   Getting appointment lists 
     
    appointments = @patient.first.appointments.active_appointment.where(["date(appnt_date) = ?" , c_date]) 
    cookies[:total_records] = cookies[:total_records] + appointments.length
    # cookies[:flag_count] = cookies[:flag_count] + recalls.length
    if (filter_arr.include?"appointment")
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
        
        
        security_role_item = {}
        security_role_item[:manage] = can? :manage , appointment
        item[:security_role] = security_role_item 
        date_wise_event[:appointments] << item 
      end
    end
    
    
    
    
    

#   Getting letter lists
    if (current_user.role.casecmp("practitioner") == 0 && !(@company.account.note_letter))  || current_user.role.casecmp("administrator") == 0
      letters = @patient.first.letters.active_letter.where(["date(created_at) = ?" , c_date])  
    else
      letters = @patient.first.letters.active_letter.where(["date(created_at) = ? and auther_id = ? " , c_date , current_user.id])
    end    
     
    cookies[:total_records] = cookies[:total_records] + letters.length
    # cookies[:flag_count] = cookies[:flag_count] + letters.length
    if (filter_arr.include?"letter")
      letters.each do |letter|
        item = {}
        item[:id] = letter.id
        item[:description] = letter.description
        item[:content] = letter.content
        
#       security role of logged in to access treatment note    
        security_role_item = {}
        security_role_item[:send_email] = can? :send_letter_via_email  , letter
        security_role_item[:print] = can? :letter_print  , letter
        security_role_item[:download] = can? :letter_print  , letter
        security_role_item[:delete] = can? :delete  , letter
        security_role_item[:modify] = can? :modify  , letter
      
        item[:security_role] = security_role_item
        
        # item[:created_by] = User.find(letter.auther_id).full_name_with_title
        date_wise_event[:letters] << item 
      end
    end
#     Getting files lists 
      
     files = @patient.first.file_attachments.order("created_at desc").where(["date(created_at) = ?" , c_date])
     cookies[:total_records] = cookies[:total_records] + files.length
     # cookies[:flag_count] = cookies[:flag_count] + files.length 
     if (filter_arr.include?"file")
       files.each do |attach_file|
         item = {}
         item[:id] = attach_file.id
         item[:name] = attach_file.avatar.original_filename
         item[:type] = attached_file_type(attach_file)
         item[:description] = attach_file.description.nil? ? "" : attach_file.description
         item[:created_on] = attach_file.created_at.strftime("%d %b %Y")
         item[:file_size] = number_to_human_size(attach_file.avatar.size)
         item[:file_url] =  request.env["HTTP_REFERER"].to_s + attach_file.avatar.to_s 
         item[:created_by] = User.find(attach_file.created_by).full_name  unless attach_file.created_by.nil?
         
         security_role_item = {}
         security_role_item[:upload] = can? :upload ,attach_file
         security_role_item[:modify] = can? :modify ,attach_file
         security_role_item[:delete] = can? :delete ,attach_file
         security_role_item[:view_name] = can? :view_name ,attach_file
         security_role_item[:clickable_link] = can? :show ,attach_file
         security_role_item[:role] = current_user.role
          
         item[:security_role] = security_role_item 
         date_wise_event[:files] << item 
       end
     end
#    Checking date wise item
    date_wise_items_count = date_wise_event[:appointments].length + date_wise_event[:treatment_notes].length + date_wise_event[:invoices].length + date_wise_event[:payments].length  + date_wise_event[:recalls].length + date_wise_event[:communications].length + date_wise_event[:files].length + date_wise_event[:letters].length     
    return date_wise_items_count > 0 ? date_wise_event : nil
  end
  
  
  def set_relation(patient , params)
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
    result[:relationship] = patient.relationship
    result[:patient_contacts_attributes] = []
    patient.patient_contacts.each do |contact|
      item = {}
      item[:id] = contact.id
      item[:contact_no] = contact.contact_no
      item[:contact_type] = contact.contact_type
      result[:patient_contacts_attributes] << item 
    end
    result[:email] = patient.email
    result[:reminder_type] = ([nil, "none","None"].include?(patient.reminder_type)) ? "none" : patient.reminder_type.downcase 
    result[:sms_marketing] = patient.sms_marketing
    result[:address] = patient.address
    result[:country] = patient.country
    result[:state] = patient.state
    result[:city] = patient.city
    result[:postal_code] = patient.postal_code
    result[:concession_type] = patient.concession.try(:id).to_s
    result[:concession_name] = patient.concession.try(:name).to_s
    result[:invoice_email] =  patient.invoice_email
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
    result[:referrer] = patient.referrer   #["first_name"] + patient.referrer["last_name"]
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
      item[:practitioner_name] = next_appointment.user.full_name_with_title
      result[:next_appointment_info] = item 
    else
      result[:next_appointment_info] = nil
    end
    result[:outstanding_balance] = patient.calculate_patient_outstanding_balance
    result[:credit_amount] = patient.calculate_patient_credit_amount
    
#     Adding filter for client page 
    result[:filter] = {appointment: current_user.client_filter_choice.appointment , treatment_note:current_user.client_filter_choice.treatment_note  , invoice: current_user.client_filter_choice.invoice , payment: current_user.client_filter_choice.payment,  recall: current_user.client_filter_choice.recall , file: current_user.client_filter_choice.attached_file , letter: current_user.client_filter_choice.letter  , communication: current_user.client_filter_choice.communication }
    
    return result
  end
  
  
  #  adding _destroy:true into params for deleting record      
  def add_destory_key_to_params(params , patient)
      all_patient_contacts_ids = patient.patient_contacts.pluck("id") 
      unless params[:patient][:patient_contacts_attributes].nil?
        patient_contacts_ids = params[:patient][:patient_contacts_attributes].map{|k| k["id"]}
        patient_contacts_deleteable = all_patient_contacts_ids - patient_contacts_ids  
      else
        params[:patient][:patient_contacts_attributes] = []
        patient_contacts_deleteable = all_patient_contacts_ids
      end
      
      patient_contacts_deleteable.each do |id|
        patient_contact = PatientContact.find(id)
        patient_contact_item = {} 
        patient_contact_item[:id] = patient_contact.id
        patient_contact_item[:contact_no] = patient_contact.contact_no
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
  
  
  def set_client_filters_for_current_user(filter , user)
    filter_model = user.client_filter_choice
    filter_model.update_attributes(appointment: false, invoice: false, payment: false, attached_file: false, letter: false, communication: false, recall: false, treatment_note: false)
    filter.each do |filter_attr|
      unless (filter_attr <=> "file") == 0
        filter_model.update_attributes(filter_attr.to_sym => true )    
      else
        filter_model.update_attributes(:attached_file => true )
      end
    end    
    
  end
end
