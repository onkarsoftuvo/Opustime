class Admin::AdminSmsController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  before_action :find_sms_plan , :only =>[:sms_package, :sms_consumption, :index,:edit,:update]
  include ApplicationHelper

  def sms_package
   # debugger

  end

  def index
    @default_sms = DefaultSm.last rescue nil
  end
  
  def sms_consumption
    @companies = Company.all
  end
  
  def new
    @sms_plan = SmsPlan.new
    @sms_groups = SmsGroup.all.select(:id, :name)
  end

  def create
    @sms_plan = SmsPlan.new(set_params)
    @sms_plan.save
    respond_to do |format|
      format.html { redirect_to admin_sms_path, notice: 'SMS Plan was successfully created.' }
    end
  end

  def edit
    @default_sms = DefaultSm.last rescue nil
    @sms_plan1 = SmsPlan.find(params[:id])
    @sms_groups = SmsGroup.all.select(:id, :name)
  end

  def update
    @sms_plan = SmsPlan.find(params[:id])
    respond_to do |format|
      if @sms_plan.update_attributes(set_params)
        format.html { redirect_to admin_sms_path, notice: 'SMS Plan was successfully Updated.' }
      else
        format.html { redirect_to admin_sms_path, notice: 'Something went wrong.' }
      end

    end

  rescue
    #render :json => {flag: false,:message=>'Something went wrong...!'}
    render :json => {flag: false, :errors => 'Something Wrong'} and return
  end

  def find_sms_plan
    @sms_plan = SmsPlan.all
  end

  def sms_number
    @sms_numbers = SmsNumber.all
  end

  private 
  
  def set_params
    params.require(:sms_plan).permit(:no_sms, :amount, :notes, :status, :sms_group_id)
  end

end
