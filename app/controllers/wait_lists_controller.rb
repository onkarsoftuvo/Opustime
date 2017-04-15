class WaitListsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :create  , :new , :edit , :destroy]
  before_action :find_waitlist , :only => [:show , :edit , :update , :destroy ]
  
  before_action :set_params_in_standard_format , :only=> [:create , :update] 
  
  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  
  def index
    begin
      WaitList.run_rake    # Removing expired waitlist
      patient_filter = doctor_filter = business_filter = nil
      
      params[:patient] = nil if params[:patient] == "undefined" || params[:patient] == "" 
      params[:doctor] = nil if params[:doctor] == "all" || params[:doctor] == ""
      params[:business] = nil if params[:business] == "all" || params[:business] == ""

      unless params[:patient].nil?
         patients =  Patient.where(["first_name LIKe ? OR last_name LIKE ? ", "%#{params[:patient]}%" , "%#{params[:patient]}%"]).pluck("id , first_name , last_name")
         patient_filter = params[:patient] unless patients.length <= 0 
      end
      
      unless params[:doctor].nil?
        doctor = @company.users.doctors.find(params[:doctor]) rescue nil
        doctor_filter = params[:doctor] unless doctor.nil?   
      end
      
      unless params[:business].nil?
        business = @company.businesses.find(params[:business]) rescue nil
        business_filter = params[:business] unless business.nil?   
      end
      #  filter wait lists as per parameters
      if patient_filter.nil? && doctor_filter.nil? && business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list  
      elsif !patient_filter.nil? && doctor_filter.nil? && business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:patient).where(["patients.first_name LIKE ? OR patients.last_name LIKE ? " , "%#{patient_filter}%" , "%#{patient_filter}%" ]).uniq
      elsif patient_filter.nil? && !doctor_filter.nil? && business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:users).where(["users.id = ?" , doctor_filter ]).uniq
      elsif patient_filter.nil? && doctor_filter.nil? && !business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:businesses).where(["businesses.id = ? " , business_filter ]).uniq
      elsif !patient_filter.nil? && !doctor_filter.nil? && business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:patient , :users).where(["(patients.first_name LIKE ? OR patients.last_name LIKE ? ) AND users.id = ? " , "%#{patient_filter}%" , "%#{patient_filter}%" , doctor_filter ]).uniq
      elsif !patient_filter.nil? && doctor_filter.nil? && !business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:patient , :businesses).where(["(patients.first_name LIKE ? OR patients.last_name LIKE ? ) AND businesses.id = ? " , "%#{patient_filter}%" , "%#{patient_filter}%" , business_filter ]).uniq
      elsif patient_filter.nil? && !doctor_filter.nil? && !business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:users , :businesses).where(["users.id = ? AND businesses.id = ? " , doctor_filter , business_filter ]).uniq
      elsif !patient_filter.nil? && !doctor_filter.nil? && business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:users , :patient).where(["users.id = ? AND (patients.first_name LIKE ? OR patients.last_name LIKE ? ) " , doctor_filter , "%#{patient_filter}%" , "%#{patient_filter}%" ]).uniq
      elsif !patient_filter.nil? && doctor_filter.nil? && !business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:businesses , :patient).where(["businesses.id = ? AND (patients.first_name LIKE ? OR patients.last_name LIKE ? ) " , business_filter , "%#{patient_filter}%" , "%#{patient_filter}%" ]).uniq
      elsif patient_filter.nil? && !doctor_filter.nil? && !business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:businesses , :users).where(["businesses.id = ? AND users.id = ? " , business_filter , doctor_filter ]).uniq
      elsif !patient_filter.nil? && !doctor_filter.nil? && !business_filter.nil?
        wait_lists = @company.wait_lists.active_wait_list.joins(:businesses , :users , :patient).where(["businesses.id = ? AND users.id = ? AND (patients.first_name LIKE ? OR patients.last_name LIKE ? ) " , business_filter , doctor_filter ,"%#{patient_filter}%" , "%#{patient_filter}%" ]).uniq      
      end
      
      result = []
      wait_lists.each do |w_list|
        item = {}
        item[:id] = w_list.id
        item[:patient_id] = w_list.patient.try(:id)
        item[:patient_name] = w_list.patient.try(:full_name)
        item[:appointment_type] = w_list.appointment_type.name
        item[:extra_info] = w_list.extra_info
        item[:availability] = w_list.availability
        item[:options] = w_list.options
        item[:phone] = []
        w_list.patient.patient_contacts.each do |contact|
          item_contact ={}
          item_contact[:contact_type] = contact.contact_type
          item_contact[:contact_no] = contact.contact_no
          item[:phone] << item_contact 
        end
        
        if w_list.remove_on.nil?
          interval = Time.diff(Time.now , w_list.appointment.created_at.to_date , '%y, %M, %w, %d')
        else
          interval = Time.diff(Time.now , w_list.remove_on.to_date , '%y, %M, %w, %d')
        end
        if interval[:day] <= 0
          item[:remove_on] = "Tomorrow"
        elsif interval[:day] > 0
          item[:remove_on] = "#{interval[:day].to_i + 1} days"
        end
        
        item[:practitioners] = []
        wait_list_practitioners = WaitListsUser.where(["wait_list_id = ? " , w_list.id])
        wait_list_practitioners.each do |wait_list_doctor|
          practi_item  = {}
          practi_item[:first_name] = wait_list_doctor.user.first_name
          practi_item[:last_name] = wait_list_doctor.user.last_name
          practi_item[:fname] = wait_list_doctor.user.first_name.to_s[0].try(:capitalize)
          practi_item[:lname] = wait_list_doctor.user.last_name.to_s[0].try(:capitalize)
          item[:practitioners]  << practi_item 
        end 
        
        result << item 
      end
      render :json=> { wait_lists:result }
  
    rescue Exception => e
      render :json=> {:error=> e.message }
    end
        
  end
  
  def new

  end
  
  def create
    unless patient_has_active_wait_list(params[:wait_list][:wait_lists_patient_attributes][:patient_id])
      wait_list = @company.wait_lists.new(params_wait_list)
      if wait_list.valid?
        wait_list.save
        result = {flag: true , wait_list_id: wait_list.id}
        render :json => result
      else
        show_error_json(wait_list.errors.messages)
      end   
    else 
      wait_list = WaitList.new
      patient = Patient.find_by_id(params[:wait_list][:wait_lists_patient_attributes][:patient_id])
      if patient.nil?
        wait_list.errors.add(:patient ,"is already on wait list")  
      else
        wait_list.errors.add("#{patient.full_name_without_title}" ,"is already on wait list") 
      end
      show_error_json(wait_list.errors.messages)  
    end
    
  end
  
  def show 
    result = {}
    begin
      result[:patient_name] = @wait_list.patient.full_name
      result[:appointment_type] = @wait_list.appointment_type.name
      result[:extra_info] = @wait_list.extra_info
      result[:availability] = @wait_list.availability
      result[:options] = @wait_list.options
      result[:phone] = []
      @wait_list.patient.patient_contacts.each do |contact|
        item ={}
        item[:contact_type] = contact.contact_type
        item[:contact_no] = contact.contact_no
        result[:phone] << item 
      end
      
      # Getting how many days wait list would be disable 
      if @wait_list.remove_on.nil?
        interval = Time.diff(Time.now , @wait_list.appointment.created_at.to_date , '%y, %M, %w, %d')
      else
        interval = Time.diff(Time.now , @wait_list.remove_on.to_date , '%y, %M, %w, %d')
      end
      if interval[:day] <= 0
        result[:remove_on] = "Tomorrow"
      elsif interval[:day] > 0
        result[:remove_on] = "#{interval[:day].to_i + 1} days"
      end
      
      render :json => result   
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end
     
  end
  
  def edit
    begin
      result = {}  
      result[:id] = @wait_list.id
      result[:remove_on] = @wait_list.remove_on
      result[:patient_id] = @wait_list.patient.id
      result[:patient_name] = @wait_list.patient.full_name
      result[:appointment_type_id] = @wait_list.appointment_type.id
      result[:options] = @wait_list.options
      result[:availability] = @wait_list.availability
      result[:extra_info] = @wait_list.extra_info
      
      # getting all associated businesses 
      result[:businesses] = []
      associated_businesses_ids =  []
      wait_list_bs = WaitListsBusiness.where(["wait_list_id = ? " , @wait_list.id]) 
      wait_list_bs.each do |wait_list_business|
        item  = {}
        item[:id] = wait_list_business.id
        item[:business_id] = wait_list_business.business.id
        item[:business_name] = wait_list_business.business.name
        item[:is_selected] =  true
        result[:businesses]  << item 
        associated_businesses_ids << wait_list_business.business.id
      end   
      
      #  Adding rest businesses name those were not selected at creation time
      rest_businesses = @company.businesses.where(["businesses.id NOT IN (?)", associated_businesses_ids]).select("businesses.id ,businesses.name")
      rest_businesses.each do |business|
        item  = {}
        item[:business_id] = business.id
        item[:business_name] = business.name
        item[:is_selected] =  false
        result[:businesses]  << item 
      end
      
      # Getting all associated practitioners info
      
      result[:practitioners] = []
      associated_practitioners_ids =  []
      wait_list_practitioners = WaitListsUser.where(["wait_list_id = ? " , @wait_list.id])
      wait_list_practitioners.each do |wait_list_doctor|
        item  = {}
        item[:id] = wait_list_doctor.id
        item[:practitioner_id] = wait_list_doctor.user.id
        item[:practitioner_name] = wait_list_doctor.user.full_name
        item[:is_selected] =  true
        result[:practitioners]  << item 
        associated_practitioners_ids << wait_list_doctor.user.id
      end   
      
      #  Adding rest practitioners name those were not selected at creation time
      rest_doctors = @company.users.doctors.where(["users.id NOT IN (?)",associated_practitioners_ids]).select("users.id ,users.first_name , users.last_name , users.title")
      rest_doctors.each do |doctor|
        item  = {}
        item[:practitioner_id] = doctor.id
        item[:practitioner_name] = doctor.full_name
        item[:is_selected] =  false
        result[:practitioners]  << item 
      end
      render :json => { wait_list: result }   
      
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end
    
  end
  
  def update
    begin
      result = {}
      if patient_has_active_wait_list(params[:wait_list][:wait_lists_patient_attributes][:patient_id] , @wait_list)
        @wait_list.update_attributes(params_wait_list)
        if @wait_list.valid?
          result = {flag: true , id: @wait_list.id }
          render :json=> result  
        else 
          show_error_json(@wait_list.errors.messages)
        end
      else
        wait_list = WaitList.new
        patient = Patient.find_by_id(params[:wait_list][:wait_lists_patient_attributes][:patient_id])
        if patient.nil?
          wait_list.errors.add(:patient ,"is already on wait list")  
        else
          wait_list.errors.add("#{patient.full_name_without_title}" ,"is already on wait list") 
        end
        show_error_json(wait_list.errors.messages)
      end
         
    rescue Exception=> e 
      render :json=> {:error=> e.message  }
    end
  end
  
  def destroy
    result = {}
    begin
      @wait_list.update_attributes(:status=> false)
      if @wait_list.valid?
        result = {flag: true , id: @wait_list.id }
        render :json=> result  
      else 
        show_error_json(@wait_list.errors.messages)
      end
    rescue Exception=> e 
      render :json=> {:error=> e.message }
    end
  end
  
#   Choose wait lists for a practitioner as per selected appointment type
  def wait_lists_as_per_appointment_type
    result = {}
    result[:urgent] = []
    result[:not_urgent] = []
    doctor = User.find_by_id(params[:doctor_id])
    appnt_types_provided_by_doctors = doctor.appointment_types.ids
    business = Business.find_by_id(params[:business_id])
    unless doctor.nil? && business.nil?
      wait_lists = WaitList.joins(:users , :businesses , :appointment_type).where("users.id = ? AND wait_lists.status = ? AND appointment_types.id IN (?) AND businesses.id = ?", doctor.id , true , appnt_types_provided_by_doctors , business.id)
      wait_lists.each do |wait_list|
        item = {}
        item[:id] = wait_list.id
        item[:patient_contacts] = []
        wait_list.patient.patient_contacts.each do |contact|
          contact_item = {}
          contact_item[:contact_no] = contact.contact_no
          contact_item[:contact_type] = contact.contact_type
          item[:patient_contacts] << contact_item 
        end
        item[:patient_id] = wait_list.patient.try(:id)
        item[:patient_name] = wait_list.patient.full_name_without_title + "-" + wait_list.appointment_type.try(:name)
        item[:appointment_type_id] = wait_list.appointment_type.try(:id)
        appnt = wait_list.appointment
        unless appnt.nil?
          item[:associated_appointment] = appnt.id
          item[:appnt_patient_name] = appnt.patient.try(:first_name)
          item[:associated_appointment_date] = appnt.appnt_date.strftime("%d %B")
        else
          item[:associated_appointment] = nil
          item[:associated_appointment_date] = nil
        end
        item[:extra_info] = wait_list.extra_info
        if wait_list[:options]["urgent"] == true
          result[:urgent] << item  
        else
          result[:not_urgent] << item
        end
                 
      end    
    end
    
    render :json => { wait_lists: result }
    
  end
  
  private
  
  def params_wait_list
    params.require(:wait_list).permit(:id , :remove_on , :extra_info, 
      :wait_lists_patient_attributes =>[:id , :patient_id , :_destroy],
      :appointment_types_wait_list_attributes =>[:id , :appointment_type_id , :_destroy],
      :wait_lists_businesses_attributes => [:id , :business_id , :_destroy],
      :wait_lists_users_attributes =>[:id , :user_id , :_destroy]
      
     ).tap do |white_listed|
       white_listed[:availability] = params[:wait_list][:availability] unless params[:wait_list][:availability].nil? 
       white_listed[:options] = params[:wait_list][:options] unless params[:wait_list][:options].nil?
     end
  end
  
  
  def set_params_in_standard_format
    unless params[:wait_list].nil?
      structure_format = {}
      structure_format[:id] = params[:wait_list][:id] unless params[:wait_list][:id].nil? 
      structure_format[:remove_on] = params[:wait_list][:remove_on]
      structure_format[:availability] = params[:wait_list][:availability]
      structure_format[:options] = params[:wait_list][:options]
      structure_format[:extra_info] = params[:wait_list][:extra_info]
      structure_format[:wait_lists_patient_attributes] = { patient_id: params[:wait_list][:patient_id] }
      structure_format[:appointment_types_wait_list_attributes] = {appointment_type_id:  params[:wait_list][:appointment_type_id]}
      
      structure_format[:wait_lists_businesses_attributes] = []
      params[:wait_list][:businesses].each do |bs_info|
        if bs_info[:is_selected]
          business_item = {}
          business_item[:id] = bs_info[:id] unless bs_info[:id].nil? 
          business_item[:business_id] =  bs_info[:business_id]
          structure_format[:wait_lists_businesses_attributes] << business_item  
        end
        if (bs_info[:is_selected]== false && !(bs_info[:id].nil?)) 
          business_item = {}
          business_item[:id] = bs_info[:id]
          business_item[:_destroy] = true
          structure_format[:wait_lists_businesses_attributes] << business_item  
        end
        
      end unless params[:wait_list][:businesses].nil?
      
      structure_format[:wait_lists_users_attributes] = []
      params[:wait_list][:practitioners].each do |doctor|
        if doctor[:is_selected]
          doctor_item = {}
          doctor_item[:id] = doctor[:id] unless doctor[:id].nil? 
          doctor_item[:user_id] =  doctor[:practitioner_id]
          structure_format[:wait_lists_users_attributes] << doctor_item  
        end
        if (doctor[:is_selected]== false && !(doctor[:id].nil?)) 
          doctor_item = {}
          doctor_item[:id] = doctor[:id]
          doctor_item[:_destroy] = true
          structure_format[:wait_lists_users_attributes] << doctor_item  
        end
        
      end unless params[:wait_list][:practitioners].nil?
      
      params[:wait_list] = structure_format
    else
      structure_format = {}
      params[:wait_list] = structure_format
    end
  end
  
  def find_waitlist
    @wait_list = WaitList.find(params[:id]) rescue nil 
  end
  
  # patient can has only single one wait list during creation or updation time
  def patient_has_active_wait_list(patient_id , wait_list = nil)
    patient = Patient.find_by_id(patient_id)
    result = false
    if wait_list.nil?
      unless patient.nil?
        if patient.wait_list.try(:status) == true
          result = true
        end
      end  
    else 
      if  wait_list.patient.id == patient_id
        result = true  
      end 
    end
    
    return result
  end
  
end
