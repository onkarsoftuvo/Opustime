class LettersController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index  , :new , :letter_templates , :get_letter_template_detail, :edit , :letter_print]
  before_action :find_letter , :only => [:edit , :update , :destroy , :letter_print , :get_data_for_send_email ]
  before_action :find_patient , :only => [:index,:create ]
  before_filter :set_current_user , :only => [ :create , :edit , :update , :destroy ]

  # load_and_authorize_resource param_method: :letter_params , except: [:letter_templates , :get_letter_template_detail]
  # before_filter :load_permissions
  
  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  
  def index 
    
  end
  
  def new 
    result = {}
    # result[:id] = nil
    result[:practitioner] = nil
    result[:contact] = nil
    result[:business] = nil
    result[:description] = nil
    result[:content] = nil 
      item = {}
      # item[:id] = nil
      item[:letter_templates_id] = nil
    result[:letter_templates_letter_attributes] = item
    render :json=> {letter: result}
    
  end
  
  def create
    (authorize! :manage_own , Letter) unless ((can? :manage_own , Letter) || (can? :manage_all , Letter))
    unless @patient.nil?
      letter = @patient.letters.new(letter_params)
      if letter.valid?
        letter.save
        result = {flag: true , id: letter.id}
        render :json=> result
      else
        show_error_json(letter.errors.messages)
      end
    else
      letter = Letter.new
      letter.errors.add(:patient , "Not found !")
      letter.valid?
      show_error_json(letter.errors.messages)  
    end
  end 
  
  def edit
    (authorize! :manage_own , Letter) unless ((can? :manage_own , Letter) || (can? :manage_all , Letter))
    result = {}
    result[:id] = @letter.id
    # result[:practitioner] = @letter.practitioner.to_i
    # result[:contact] = @letter.contact.to_i
    # result[:business] = @letter.business.to_i
    result[:description] = @letter.description
    result[:content] = @letter.content
      # item = {}
      # item[:id] = @letter.letter_templates_letter.id
      # item[:letter_templates_id] = @letter.letter_template.id
    # result[:letter_templates_letter_attributes] = item
    # letter_tabs ={}
    
    # avail_tabs = @letter.letter_template.addition_tabs 
    # practitioner = business = contact = refer_doc = patient = nil 
#   choosing drop downs and getting their values in listing -   
    # avail_tabs.each {|key ,value|
      # if (key <=> "practitioner") == 0 && value == true
        # letter_tabs[:practitioner] = @company.users.doctors.select("id,first_name ,last_name")
      # elsif (key <=> "business") == 0 && value == true
        # letter_tabs[:business] = @company.businesses.select("id , name").order("created_at asc") 
      # elsif (key <=> "contact") == 0 && value == true
        # letter_tabs[:contact] = @company.contacts.active_contact.select("id , first_name , last_name")
      # end
      # }
    # render :json=> {letter: result, tabs_info: letter_tabs }
    render :json=> {letter: result}
    
  end
  
  def update
    (authorize! :manage_own , Letter) unless ((can? :manage_own , Letter) || (can? :manage_all , Letter))
    @letter.update_attributes(letter_params)
    if @letter.valid?
      result = {flag: true , id: @letter.id}
      render :json=> result
    else
      show_error_json(@letter.errors.messages)
    end
  end
  
  def destroy
    (authorize! :destroy , Letter)
    @letter.update_attributes(:status=> false)
    if @letter.valid?
      result = {flag: true , id: @letter.id}
      render :json=> result
    else
      show_error_json(@letter.errors.messages)
    end
  end
  
  def letter_templates
    session[:patient_id] = params["patient_id"]
    letter_templates = @company.letter_templates.active_letter.select("letter_templates.id, letter_templates.template_name")
    render :json=> letter_templates
  end
  
  def get_letter_template_detail
    result = {}
    letter_tabs ={}
#   Replacing symbols of letter template with appropriate values    
    letter_template = @company.letter_templates.active_letter.select("letter_templates.id , letter_templates.template_name  , letter_templates.default_email_subject , letter_templates.template_body , letter_templates.addition_tabs").find(params[:id]) rescue nil
    avail_tabs = letter_template.addition_tabs 
    practitioner = business = contact = refer_doc = patient = nil 
#   choosing drop downs and getting their values in listing -   
    avail_tabs.each {|key ,value|
      if (key <=> "practitioner") == 0 && value == true
        letter_tabs[:practitioner] = @company.users.doctors.select("id,first_name ,last_name")
        unless params[:practitioner_id].nil?
          practitioner =  @company.users.doctors.find(params[:practitioner_id])
          result[:practitioner] = practitioner.try(:id)
        else
          practitioner =  @company.users.doctors.first unless  letter_tabs[:practitioner].nil?
          result[:practitioner] = practitioner.try(:id) 
        end 
      elsif (key <=> "business") == 0 && value == true
        letter_tabs[:business] = @company.businesses.select("id , name").order("created_at asc") 
        unless params[:business_id].nil?
          business = @company.businesses.where(["businesses.id = ?", params[:business_id]]).first 
          result[:business] = business.try(:id)
        else 
          business = @company.businesses.head.first
          result[:business] = business.try(:id)
        end
      elsif (key <=> "contact") == 0 && value == true  
        letter_tabs[:contact] = @company.contacts.active_contact.select("id , first_name , last_name")
      else
        letter_tabs[key.to_sym] = []
      end
      }
      unless params[:contact_id].nil? || params[:contact_id] =="undefined"
        contact = @company.contacts.active_contact.find(params[:contact_id])
        result[:contact] = contact.try(:id)
      else 
        contact = nil
      end
      
#   checking which one practitioner is selected         
    patient = Patient.find(session[:patient_id]) unless session[:patient_id].nil?
    refer_doc = patient.contact unless patient.try(:contact).nil?
    unless letter_template.nil?
      
      item = {}
      item[:letter_template_id] = letter_template.id
      item[:letter_template_name] = letter_template.template_name
      result[:letter_templates_letter_attributes] = item
      result[:description] = letter_template.default_email_subject
      replace_data = matcher_var(patient , practitioner , business , contact , refer_doc ) 
      matcher = /#{replace_data.keys.join('|')}/
      result[:content] = letter_template.template_body.gsub(matcher, replace_data)
    end 
    render :json=> {:letter => result , tabs_info: letter_tabs } 
  end
  
  def set_current_user
    Letter.current = current_user
  end
  
#   letter print functionality 
  def letter_print
#   Getting margin info for printing from  setting- document and printing     
    print_setting = @company.document_and_printing
    top_margin = print_setting.l_top_margin
    bottom_margin = print_setting.l_bottom_margin
    bleft_margin = print_setting.l_bleft_margin
    bright_margin = print_setting.l_right_margin
    @logo_url = print_setting.logo
    @logo_size = print_setting.logo_height
    @show_logo = print_setting.l_display_logo
    @logo_underneath_space = print_setting.l_space_un_logo.to_i
    respond_to do |format|
      # format.html
      format.pdf do
        render :pdf => "pdf_name.pdf" , 
               :layout => '/layouts/pdf.html.erb' ,
               :disposition => params[:download].present? ? 'attachment':'inline' ,
               :template    => "/letters/letter_print.pdf.erb",
               :show_as_html => params[:debug].present? ,
               :footer=> { right: '[page] of [topage]' },
               :margin=>  {   top:               top_margin.to_i,                     # default 10 (mm)
                              bottom:            bottom_margin.to_i,
                              left:              bleft_margin.to_i,
                              right:             bright_margin.to_i }
      end
    end 
    
  end
  
  def get_data_for_send_email
    result = {}
    patient = @letter.patient
    contact = Contact.find(@letter.contact) rescue nil
    company = patient.company
    refer_doc_id = patient.refer_doctor["id"] unless patient.refer_doctor.nil?
    result[:id] =@letter.id
    
    item = {}
    item[:patient_email] = patient.email.nil? ? nil : patient.email
    item[:contact_email] = contact.try(:email).nil? ? nil : contact.try(:email)  
    item[:refer_doc] = refer_doc_id.nil? ? nil : (company.contacts.where(:id=> refer_doc_id).first.try(:email))
    result[:custom_email] = []
    result[:send_to] = item 
    result[:letter_subject] = @letter.letter_template.default_email_subject
    result[:recepient_list] = []

#   Adding company communication email as recepeint  
    item = {}
    item[:recepeint_email] = company.communication_email
    item[:recepeint_name] = company.company_name
    result[:recepient_list] << item 

#   Adding company first admin user email as recepeint
    first_admin = company.users.admin.first rescue nil 
    item = {}
    item[:recepeint_email] = first_admin.email unless first_admin.nil?
    item[:recepeint_name] = first_admin.full_name
    result[:recepient_list] << item
       
    result[:from] = company.communication_email
    result[:format] = true
    result[:email_content]  = nil 
    # session[:letter_id] = @letter.id    
    render :json=> result 
    
  end
  
  def send_letter_via_email
    result = {}
    email_recipients = params[:send_to].values.flatten.compact
    unless params[:custom_email].nil?
      custom_recepeint_emails = params[:custom_email].map{|k| k["email"]}
      email_recipients =  (email_recipients  + custom_recepeint_emails).uniq
    end
    email_recipients.delete("")
    if email_recipients.count > 0
      unless (params[:letter_subject].nil? || params[:letter_subject].blank?)
        letter = Letter.find(params[:id]) rescue nil unless params[:id].nil?
        begin
        if params[:format]
          LettersWorker.perform_async(email_recipients , params[:from] ,  letter.id , params[:letter_subject])
        else
          html = render_to_string(:action => :letter_print, :layout => "/layouts/pdf.html.erb", :formats => [:pdf] , :locals=>{:@letter=> letter}) 
          pdf = WickedPdf.new.pdf_from_string(html) 
          LetterMailer.letter_email(email_recipients , params[:from] ,  letter , params[:letter_subject] , params[:email_content] , pdf).deliver_now
          patient = letter.patient
          patient.communications.create(comm_time: Time.now, comm_type: "email", category: "Letter", direction: "sent", to: patient.email, from: patient.company.communication_email, message: Nokogiri::HTML(letter.content).text , send_status: true) unless patient.nil?
        end
        rescue Exception=> e
          puts "Errors -  #{e.message}"
        end
        render :json=> {flag: true}
      else
        letter = Letter.new
        letter.errors.add(:subject , "can't be left blank !")
        show_error_json(letter.errors.messages)
      end
    else
      letter = Letter.new
      letter.errors.add(:atleast , "one email recepiant should be selected ! ")
      show_error_json(letter.errors.messages)
    end
  end
  
  private
  
  def letter_params
    params.require(:letter).permit(:id , :practitioner , :contact , :business , :description , :content,
      :letter_templates_letter_attributes => [:id , :letter_template_id]
    )
  end
  
  def find_patient
     @patient = Patient.find(params[:patient_id]) rescue nil
  end
  
  def find_letter
    @letter = Letter.find(params[:id]) rescue nil 
  end
  
  def matcher_var(patient=nil , practitioner=nil , business=nil , contact=nil , refer_doc=nil )
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
 #      key value for practitoner  tab
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
#    key value for business tab
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
#      key value for contact tab
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
#      key value for refer doc tab 
     unless refer_doc.nil?
       refer_doc_tab = ReferringDoctorTab.first
       str["{{#{refer_doc_tab.full_name}}}"] = "#{refer_doc.full_name}"
       str["{{#{refer_doc_tab.title}}}"] = "#{refer_doc.title}"
       str["{{#{refer_doc_tab.first_name}}}"] = "#{refer_doc.first_name}"
       str["{{#{refer_doc_tab.last_name}}}"] = "#{refer_doc.last_name}"
       str["{{#{refer_doc_tab.email}}}"] = "#{refer_doc.email}"
       str["{{#{refer_doc_tab.mobile_number}}}"] = "#{refer_doc.get_mobile_no_type_wise("mobile")}"
     end
     
#      key value for general tab 
       general_tab = GeneralTab.first
       str["{{#{general_tab.current_date}}}"] = Date.today
     
     return str
   end
   
   
  
end
