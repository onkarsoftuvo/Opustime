class Admin::AdminSubscriptionController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  before_action :find_plan, :only => [:edit, :update, :destroy]
  before_action :find_business, :only => [:index, :edit, :update]

  def index
  end

  def show
  end

  def new
    @plan = Plan.new
  end

  def edit

  end

  def create
    if current_owner.role.to_s.eql?('super_admin_user')
      @plan = Plan.new(plan_params)
      @plan.assign_attributes(:owner => current_owner)
      if @plan.save
        render :json => {flag: true, :message => 'Plan created successfully.'} and return
      else
        render :json => {flag: false, :errors => admin_error_json(@plan.errors.messages)} and return
      end
    else
      render :json => {flag: false, :message => 'Permission Denied...!'} and return
    end

  end

  def update
    @plan.assign_attributes(plan_params)
    if @plan.save
      render :json => {flag: true, :message => 'Plan updated successfully.'} and return
    else
      render :json => {flag: false, :errors => admin_error_json(@plan.errors.messages)} and return
    end
  rescue
    render :json => {flag: false, :message => 'Something went wrong...!'} and return
  end

  def destroy
    if current_owner.role.to_s.eql?('super_admin_user')
      @plan.update_columns(:status => false)
      response = {:success=>'Plan destroyed Successfully '}
    else
      response = {:warning=>'Permission Denied..!'}
    end
    respond_to do |format|
      format.html { redirect_to admin_subscription_index_path, :flash => response }
    end
  end

  def find_business
    if params[:plan_id].present? || params[:sub_id].present?
      @subscribe = Plan.where(["plans.id = ? OR plans.id = ? AND status = ? ", params[:plan_id], params[:sub_id], true])
    else
      @subscribe = Plan.all.where(status: true)
    end

  end

  private

  def find_plan
    @plan = Plan.find(params[:id])
  end

  def plan_params
    params.require(:plan).permit(:name, :price, :owner_id, :no_doctors, :category, :information, :status)
    #params.permit(:name, :price, :no_doctors, :category,:information,:status)
  end


  def admin_error_json(error_arr, flag= false)
    error_msg = []
    error_arr.keys.each do |key|
      item= {}
      item[:error_name] = key.to_s.split("_").join(" ")
      item[:error_msg] = error_arr[key].first
      error_msg << item
    end
    return error_msg
  end

end
