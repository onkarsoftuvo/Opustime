class Admin::AdminSmsSettingController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize

  before_action :find_sms_setting, :only => [:index]
  before_action :find_company, :only => [:sms_credit]

  def index
  end

  def new

  end

  def create
    default_sms = DefaultSm.find_by_id(params[:id])
    default_sms.assign_attributes(set_params)
    response= default_sms.save ? {:status=>true,:message=>'Successfully updated'} : {:status=>false,:message=>default_sms.errors.full_messages.to_sentence}
    render :json => {flag: response[:status] , :message => "#{response[:message] }"}

  end

  def edit
    @sms_default1 =@current_owner.default_sm
  end


  def sms_credit
    @comp = Company.find_by_id(params[:id])
    respond_to do |format|
      format.js { render 'show_modal' }
    end
  end

  def sms_edit
    @company = Company.find_by_id(params[:company_id])
    @company.sms_setting.update_attributes(:default_sms => params[:default_sms])
    respond_to do |format|
      format.html { redirect_to list_business_list_path, notice: 'Default SMS was successfully updated.' }
    end
  end

  def update
    #@sms_setting = SmsSetting
    @default_sms.update_attributes(set_params)
    respond_to do |format|
      format.html { redirect_to admin_sms_path, notice: 'Default SMS was successfully updated.' }
    end
  end

  def find_company
    @comp = Company.find(params[:id])
    session[:comp_id] = @comp.id
  end

  def find_sms_setting
    @sms_default = DefaultSm.all
  end

  private

  def set_params
    params.permit(:sms_no)
  end
end
