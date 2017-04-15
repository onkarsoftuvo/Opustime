class HomeController < ApplicationController
  respond_to :json
  before_filter :authorize , :only=> [:dashboard_rolewise_authentication]
  # before_action :which_company , :only=> [:dashboard_rolewise_authentication]
  
  def index
    if session[:user_id].nil?
      unless cookies[:user_id].nil?
        current_user
      else
        reset_session
        @current_user = nil      
      end
    else
      current_user  
    end 
  end

  def get_theme
    render :json => {theme_name: 'blue_theme'}
  end
  
  def dashboard_rolewise_authentication
    result = {}

    # result[:setting] =  can? :manage , Company
    result[:setting] , result[:setting_sub_modules] = get_setting_sub_modules
    result[:patient] =  can? :index , Patient
    result[:product] =  can? :index , Product
    result[:expense] =  can? :index , Expense
    result[:contact] =  can? :index , Contact
    result[:communication] =  can? :index , Communication
    result[:invoice] = can? :index , Invoice
    result[:payment] = can? :index , Payment
    result[:appointment] = can? :index , Appointment
    result[:report] = is_report_authorized
    result[:report_sub_modules] = report_sub_modules
    render :json => result 
    
  end

  def is_report_authorized
    (can? :manage, :report) || (can? :index, :patient_report) || (can? :patients_without_upcoming_appnt, :patient_report) || (can? :patient_listing, :patient_report) || (can? :daily_payment, :daily_report) || (can? :payment_summary , :payment_report) || (can? :outstanding_invoice , :patient_report) || (can? :practitioner_revenue , :practitioner_report) || (can? :manage , :expense_report) || (can? :recall_patient , :patient_report) || (can? :refer , :refer_patient)
  end

  def report_sub_modules
    result = {}
    result[:appointment] = can? :manage, :report
    result[:upcoming_bday] =  can? :index, :patient_report
    result[:ptn_wt_upcm_appnt] = can? :patients_without_upcoming_appnt, :patient_report
    result[:patient] = can? :patient_listing, :patient_report
    result[:daily_report] = can? :daily_payment, :daily_report
    result[:payment_summary] = can? :payment_summary , :payment_report
    result[:outstanding_invoice] = can? :outstanding_invoice, :patient_report
    result[:practitioner_revenue] = can? :practitioner_revenue , :practitioner_report
    result[:expense] = can? :manage , :expense_report
    result[:recall] = can? :recall_patient , :patient_report
    result[:refer] = can? :refer , :refer_patient
    return result
  end

  def get_setting_sub_modules
    item  = {}
    show_setting = false

    item['account_module'] = ((can? :manage , Account) || (can? :manage , Business) || (( can? :index , User))) # || (can? :view_own , User) || (can? :manage_all , User)))

    item['acc_sub_modules'] = {
        account: (can? :manage , Account) ,
        business: (can? :manage , Business) ,
        user: (( can? :index , User)) # || (can? :view_own , User) || (can? :manage_all , User))
    }
    count = 0
    item['acc_sub_modules'].values.each {|k| count+= 1 if  k== true}
    item['acc_total'] = count


    item['billing_module'] = ((can? :manage , BillableItem) || (can? :manage , PaymentType) || ( can? :manage , TaxSetting) || (can? :manage , InvoiceSetting))
    item['billing_sub_modules'] = {
        service: (can? :manage , BillableItem) ,
        payment_type: (can? :manage , PaymentType) ,
        tax: (can? :manage , TaxSetting) ,
        invoice_setting: (can? :manage , InvoiceSetting)
    }
    count = 0
    item['billing_sub_modules'].values.each {|k| count+= 1 if  k== true}
    item['billing_total'] = count

    item['booking_module'] = ((can? :manage , AppointmentType) || (can? :manage , OnlineBooking) || ( can? :manage , AppointmentReminder))
    item['booking_sub_modules'] = {
        appointment_type: (can? :manage , AppointmentType) ,
        online_booking: (can? :manage , OnlineBooking) ,
        appointment_reminder: (can? :manage , AppointmentReminder)

    }
    count = 0
    item['booking_sub_modules'].values.each {|k| count+= 1 if  k== true}
    item['booking_total'] = count

    item['communication_module'] = (((can? :index , RecallType) || (can? :edit , RecallType) || (can? :destroy , RecallType)) || (can? :manage , LetterTemplate) || ( can? :manage , SmsTemplate))
    item['communication_sub_modules'] = {
        recall_type: ((can? :index , RecallType) || (can? :edit , RecallType) || (can? :destroy , RecallType)) ,
        letter_template: (can? :manage , LetterTemplate) ,
        sms_template: ( can? :manage , SmsTemplate)

    }
    count = 0
    item['communication_sub_modules'].values.each {|k| count+= 1 if  k== true}
    item['communication_total'] = count

    item['client_module'] = ((can? :manage , TemplateNote) || (can? :manage , ReferralType) || ( can? :manage , Concession))
    item['client_sub_modules'] = {
        template_note: (can? :index , TemplateNote) ,
        referral_type: (can? :manage , ReferralType) ,
        discount_type: ( can? :manage , Concession)

    }
    count = 0
    item['client_sub_modules'].values.each {|k| count+= 1 if  k== true}
    item['client_total'] = count


    item['dc_data_module'] = ((can? :manage , Import) || check_export_permission? || ( can? :manage , DocumentAndPrinting))
    item['dc_data_sub_modules'] = {
        import:  (can? :index , Import) ,
        export: check_export_permission? ,
        dc_print: ( can? :manage , DocumentAndPrinting)
    }
    count = 0
    item['dc_data_sub_modules'].values.each {|k| count+= 1 if  k== true}
    item['dc_data_total'] = count

    item['subscription_module'] = ((can? :manage , Subscription) || ( can? :manage , SmsSetting))
    item['subscription_sub_modules'] = {
        subscription:  (can? :index , Subscription) ,
        sms_setting: ( can? :manage , SmsSetting)

    }
    count = 0
    item['subscription_sub_modules'].values.each {|k| count+= 1 if  k== true}
    item['subscription_total'] = count


    item['integration_module'] = can? :manage , :integration

    show_setting  = (item['integration_module']) || (item['subscription_module']) || (item['dc_data_module']) ||
        item['communication_module'] || (item['client_module']) || (item['booking_module']) || (item['billing_module']) ||
        item['account_module']



    return show_setting , item
  end

  def check_export_permission?
    (can? :export , Product) || (can? :export , Invoice) || (can? :export , Payment) || (can? :export , Expense) || (can? :export , :other)
  end
   
end
