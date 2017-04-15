class LetterTemplatesController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :create ]
  before_action :find_letter_template , :only => [:edit , :update , :destroy]

  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }



  def index
 	letter_templates = @company.letter_templates.active_letter.order("created_at desc").select("id, template_name, template_body,default_email_subject")
  	render :json=> letter_templates
  end

  def new
    authorize! :manage , LetterTemplate
    letter_template =  LetterTemplate.new
   	result = {}
    result[:letter_template] = letter_template
   	render :json => result
  end

  def create
    authorize! :manage , LetterTemplate
  	letter_template =@company.letter_templates.new(letter_template_params)
    if letter_template.valid?
      letter_template.save
      result = {flag: true , id:letter_template.id}
      render :json => result
   	else
      show_error_json(letter_template.errors.messages) 
  	end
  end
  
  def edit
    authorize! :manage , LetterTemplate
  	letter_template = @letter_template.select("id , template_name , default_email_subject , template_body ").first
  	result = {}
  	result["letter_template"] = letter_template
  	render :json => result

  end

 def update
   authorize! :manage , LetterTemplate
   letter_template = @letter_template.first
 	 letter_template.update_attributes(letter_template_params)
     if letter_template.valid?
        result = {flag: true }
        render :json => result  
     else 
      show_error_json(letter_template.errors.messages)
     end
 end

  def destroy
    authorize! :manage , LetterTemplate
  	letter_template = @letter_template.first
  	letter_template.update_attributes(:status=> false)
    if letter_template.valid?
      result = {flag: true }
      render :json => result  
    else 
      show_error_json(letter_template.errors.messages)
    end
  end
  
  def get_all_tabs_info
    result = {}
    result[:patient] = PatientTab.select("full_name , title , first_name , last_name , mobile_number , home_number , work_number , fax_number , other_number , email , old_reference_id , id_number , address , city , post_code, state , country , dob , gender , occupation , emergency_contact , referral_source , medicare_number , notes , first_appt_date , first_appt_time , most_recent_appt_date , most_recent_appt_time , next_appt_date , next_appt_time").first
    result[:practitioner] = PractitionerTab.select("full_name , full_name_with_title , title , first_name , last_name , designation , email , mobile_number ").first
    result[:business] = BusinessTab.select("name , full_address , address , city , state , post_code , country , registration_name , registration_value , website_address , ContactInformation").first
    result[:contact] = ContactTab.select("full_name , title , first_name , last_name , preferred_name , company_name , mobile_number , home_number , work_number , fax_number , other_number , email , address , city , state , post_code , country , occupation , notes , provider_number").first
    result[:refer_doc] = ReferringDoctorTab.select("full_name , title , first_name , last_name , preferred_name , company_name , mobile_number , home_number , work_number , fax_number , other_number , email , address ,  city , state , post_code , country , occupation , notes , provider_number").first
    result[:general] = GeneralTab.select("current_date").first
    render :json=> result
  end

   private

   def letter_template_params
     params.require(:letter_template).permit(:id, :template_name, :template_body, :default_email_subject).tap do |whitelisted|
      whitelisted[:addition_tabs] = set_aditional_tabs_info(params)       
     end
   end

   def find_letter_template
   	 @letter_template = LetterTemplate.where(:id=> params[:id])
   end
   
#  setting tabs selection which one are using in content   
   def set_aditional_tabs_info(params)
     item  = {practitioner: false , business: false , contact: false}
     content = params[:letter_template][:template_body]
     content  = "" if params[:letter_template][:template_body].nil?
     if content.include?"{{Contact."
       item[:contact] = true
     end
     if content.include?"{{Business."
       item[:business] = true
     end
     if content.include?"{{Practitioner."
       item[:practitioner] = true
     end
     return item
   end
end