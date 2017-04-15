class AccountsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:edit , :update , :get_attendee]

  # load_and_authorize_resource  param_method: :account_params , except: [:get_attendee]
  before_filter :load_permissions
  
  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  
  def edit
    (authorize! :manage , Account) unless (can? :manage , Account)
    account = @company.account
    result = {}
    result[:id] = account.id
    result[:first_name] = account.first_name
    result[:last_name] = account.last_name
    result[:email] = account.email
    result[:country] = account.country
    result[:company_name] = account.company_name
    result[:attendees] = account.attendees
    result[:logo] = account.logo
    result[:show_time_indicator] = account.show_time_indicator
    result[:patient_name_by] = account.patient_name_by
    result[:multi_appointment] = account.multi_appointment
    result[:calendar_setting] = account.calendar_setting
    result[:communication_email] = account.communication_email
    result[:show_attachment] = account.show_attachment
    result[:note_letter] = account.note_letter
    result[:time_zone] = account.time_zone
    result[:show_finance] = account.show_finance
    result[:theme_name] = account.theme_name.nil? ? DEFAULT_THEME_NAME : account.theme_name
    render :json=> result
  end
#   Update functionality except file upload
  def update
    (authorize! :manage , Account) unless (can? :manage , Account)
    begin
      comp_account = Account.find(params[:id]) rescue nil
      comp_account.update_attributes(account_params) unless comp_account.nil?
      @company.update_column(:communication_email, account_params[:communication_email]) unless comp_account.nil?
      @company.update_column(:company_name, comp_account.company_name)
      if comp_account.valid?
        render :json=>{:flag=> true , :id=> comp_account.id}
      else
        show_error_json(comp_account.errors.messages)
      end
    rescue Exception=> e
      error_handle_account = Account.new
      error_handle_account.errors.add(:error , e.messages)
      show_error_json(error_handle_account.errors.messages)
    end
  end
  
  #   Update functionality for file upload
  def logo_upload
    (authorize! :manage , Account) unless (can? :manage , Account)
    comp_account = Account.find(params[:id]) rescue nil
    logo = params[:file]
    comp_account.update(:logo=> logo) unless logo.blank?
    if comp_account.valid?
      render :json=> {flag: true}    
    else
      show_error_json(comp_account.errors.messages)
    end
  end

  def get_attendee
    account = @company.account
    head_location = @company.businesses.head.try(:first)

    attendee_name = account.attendees
    result = {attendee_name: attendee_name}
    result[:logo_url] =  account.logo.url
    # result[:c_code] = account.country
    result[:time_zone] = account.time_zone
    result[:theme_name] = account.theme_name
    result[:c_code] = head_location.try(:country)
    result[:bs_head_state] = head_location.try(:state)
    render :json => result
  end
  
  private 
  
  def account_params
    params.require(:account).permit(:id , :first_name, :last_name , :email, :country, :time_zone, :attendees, :note_letter, :show_finance, :show_attachment, :communication_email, :multi_appointment, :show_time_indicator, :patient_name_by , :company_name, :calendar_setting , :theme_name).tap do |whitelisted|
      whitelisted[:calendar_setting] = params[:account][:calendar_setting]
    end 
  end
  
end
