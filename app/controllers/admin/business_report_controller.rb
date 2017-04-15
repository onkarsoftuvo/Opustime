class Admin::BusinessReportController < ApplicationController
  layout "application_admin"
  add_breadcrumb "Home", :admin_panel_view_path
  #add_breadcrumb "my", :my_path

  before_action :admin_authorize
  #before_filter :find_company, :only=>[:edit_user, :business_detail, :edit_business, :edit_patient]
  before_action :find_business, :only=>[:business_list, :business_customer, :business_detail, :business_detail_list,:edit_user,:edit_business, :edit_patient, :business_earning,:business_location,:business_financial]
  before_action :find_company, :only=>[:business_detail_list , :sms_credit]
  before_action :set_tab_list, :only=>[:business_detail_list]

  def business_list
    add_breadcrumb "business", :list_business_list_path
    @count = 0

    respond_to do |format|
      format.html
      format.json { render json: CompanyDatatable.new(view_context) }
    end

  end
  def business_customer
    add_breadcrumb "Business Customer", :list_business_customer_path
    @count = 0
    respond_to do |format|
      format.html
      format.json { render json: BusinessCustomerDatatable.new(view_context) }
    end
  end
  def business_earning
    add_breadcrumb "Business Earning", :earn_business_earning_path
    @count = 0
    respond_to do |format|
      format.html
      format.json { render json: BusinessEarningDatatable.new(view_context) }
    end
  end
  def business_location
    add_breadcrumb "Business Location", :earn_business_location_path
    @count = 0
  end
  def business_financial
    add_breadcrumb "Business Financial", :earn_business_financial_path
    @count = 0
    respond_to do |format|
      format.html
      format.json { render json: BusinessFinancialReportDatatable.new(view_context) }
    end
  end
  
  def business_detail  
    @count = 0
    @comp = Company.find(params[:id])
    @business = @comp.businesses.first
      session[:comp_id] = @comp.id
    add_breadcrumb "Business Detail", "/business/#{@comp.id}/details"
  end

  def demo
    @customer = @comp.patients.where(["patients.first_name LIKE ? OR patients.country LIKE ?", "%#{params[:Customer]}%", params[:project][:country]])
  end 

  def business_detail_list
    subscription =  @comp.subscription
    current_plans = []
    no_practitioners  =@comp.users.doctors.count
    add_breadcrumb "business", :list_business_list_path
    add_breadcrumb "business detail list", "/business/#{@comp.id}/details_list"
#   To add subscription details
   
    @subscription_details = {current_plan: subscription.name , avail_practi: no_practitioners , max_practi: subscription.doctors_no , next_billing_date: (subscription.purchase_date+30.days) , category: subscription.category , fee: subscription.cost , remaining_days: 30 -(Date.today.mjd-subscription.purchase_date.mjd) }
    if params[:tab_no] == "0"  
      if params[:User].blank?
         @users = @comp.users.where(["users.role LIKE ?","%#{params[:role]}%"]).uniq
        else
        #@users = @comp.users.joins(:practi_info=> :practitioner_avails).where(["users.first_name LIKE ?  OR users.last_name LIKE ? OR practitioner_avails.business_id=?", "%#{params[:User]}%",  "%#{params[:User]}%", params[:business][:id]]).uniq
        #@users = @comp.users.where(["users.first_name LIKE ?  OR users.last_name LIKE ? OR users.id=? ", "%#{params[:User]}%",  "%#{params[:User]}%", "%#{params[:user][:role]}%"]).uniq
        @users = @comp.users.where(["users.first_name LIKE ?  OR users.last_name LIKE ? or users.role LIKE ?", "%#{params[:User]}%",  "%#{params[:User]}%", "%#{params[:role]}%"]).uniq
      end
    elsif params[:tab_no] == "1"
      if params[:Business].blank?
        @business = @comp.businesses.where([" businesses.id=?",  params[:business][:id1]]).uniq
      else
        @business = @comp.businesses.where(["businesses.name LIKE ?"  , "%#{params[:Business]}%"]).uniq
      end
    elsif params[:tab_no] == "2"
      @customer = @comp.patients.where(["patients.first_name LIKE ? OR patients.country LIKE ?", "%#{params[:Customer]}%", params[:project][:country]])
      cookies[:tab_no] = params[:tab_no]
    elsif params[:tab_no] == "6"
      sms1 = @comp.sms_logs.where(["(object_type = ? AND object_id IN (?)) OR (object_type = ? AND object_id IN (?))  OR (object_type = ? AND object_id IN (?)) " , "Patient" , Patient.where(["patients.first_name LIKE ? OR patients.last_name LIKE ?  ", "%#{params[:name]}%" , "%#{params[:name]}%"]).ids ,  "Contact" ,  Contact.where(["contacts.first_name LIKE ? OR contacts.last_name LIKE ? ", "%#{params[:name]}%", "%#{params[:name]}%"]).ids ,  "Contact" ,  User.where(["users.first_name LIKE ? OR users.last_name LIKE ? ", "%#{params[:name]}%", "%#{params[:name]}%"]).ids])
      sms2 = @comp.sms_logs.where(["sms_logs.contact_to LIKE ? OR sms_logs.contact_from LIKE ?","%#{params[:phone_no]}%","%#{params[:phone_no]}%"])
      if params[:phone_no].blank? && params[:name].blank?
        @sms = @comp.sms_logs
      elsif !params[:phone_no].nil? && params[:name].blank?
        @sms = @comp.sms_logs.where(["sms_logs.contact_to LIKE ? OR sms_logs.contact_from LIKE ?","%#{params[:phone_no]}%","%#{params[:phone_no]}%"])
      elsif !params[:name].nil? && params[:phone_no].blank?
        @sms =  @comp.sms_logs.where(["(object_type = ? AND object_id IN (?)) OR (object_type = ? AND object_id IN (?))  OR (object_type = ? AND object_id IN (?)) " , "Patient" , Patient.where(["patients.first_name LIKE ? OR patients.last_name LIKE ?  ", "%#{params[:name]}%" , "%#{params[:name]}%"]).ids ,  "Contact" ,  Contact.where(["contacts.first_name LIKE ? OR contacts.last_name LIKE ? ", "%#{params[:name]}%", "%#{params[:name]}%"]).ids ,  "Contact" ,  User.where(["users.first_name LIKE ? OR users.last_name LIKE ? ", "%#{params[:name]}%", "%#{params[:name]}%"]).ids])
        #@sms = sms.first.object.full_name
        #@sms = @comp.sms_logs.joins(:patient).where(["patients.first_name LIKE ?", "%#{params[:name]}%"])
      else
        @sms = sms1 + sms2
      end
      #@sms = @comp.sms_logs.where(["sms_logs.contact_to LIKE ? OR sms_logs.contact_from LIKE ?","%#{params[:phone_no]}%","%#{params[:phone_no]}%"])
      #@sms = @comp.sms_logs.joins(:user).where(["users.first_name LIKE ?", "%#{params[:name]}%"]) 
      #@sms = @comp.sms_logs.joins(:patient).where(["patients.first_name LIKE ?", "%#{params[:name]}%"]) 
      #@sms = @comp.sms_logs.joins(:contact).where(["contacts.first_name LIKE ?", "%#{params[:name]}%"])   
      elsif params[:tab_no] == "8"
        if params[:product_name].blank?
          @products = @comp.products
        else
          @products = @comp.products.where(["products.name LIKE ? ", "%#{params[:product_name]}%"])
        end
    else 
    end
  end
  
  def edit_user
    #@users = Company.find(session[:comp_id]).users.find(params[:id])
    @user = User.find(params[:id])
    add_breadcrumb "Edit User", "/business/#{@user.id}/edit_user"
    #@users = @com.users.find(params[:id])
  end


  def edit_business
    @business =  Business.find(params[:id]) 
    add_breadcrumb "Edit Business", "/business/#{@business.id}/edit_business"
  end
  
  def edit_patient  
    @patient = Patient.find(params[:id])
    add_breadcrumb "Edit patient", "/business/#{@patient.id}/edit_patient"
  end

  def sms_credit_popup
    @comp_id = params[:id]
  end

  def sms_credit
    unless @comp.nil?
      sms_setting = @comp.sms_setting
      exist_sms_no = sms_setting.default_sms
      sms_setting.update_column(:default_sms , (exist_sms_no.to_i + params[:sms_no].to_i) )
      redirect_to :back , :notice => "Sms credit has been added successfully !"
    end
  end

  def clear_attempts
    user = User.find_by(params[:id])
    comp = user.company
    unless comp.nil? || user.nil?
      comp.attempts.where(email: user.email).destroy_all
    end
  end

  private

  def find_company
    @comp =  Company.find(params[:id])
    session[:comp_id] = @comp.id
  end

  def set_tab_list
    @count_user = 0
    @count_business = 0
    @count_customer = 0
    @count_appointment = 0 
    @count_product = 0
    @customer = @comp.patients
    @business = @comp.businesses
    @users = @comp.users.where(["acc_active = ? " , true])
    @sms = @comp.sms_logs
    @products = @comp.products
    @expenses = @comp.expenses
  end

  def find_business
    unless params[:project].nil?
      if params[:project].keys.include?"state"
        if params[:project][:state] == ""
          @company = Company.all
        else
          @company = Company.joins(:businesses).where(["businesses.state = ? OR businesses.city = ?  " ,"IN-" +  params[:project][:state],params[:project][:city]])
        end
      end
    else
      @company = Company.all 
    end
  end
end

