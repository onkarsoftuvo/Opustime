class Admin::LogsController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  # before_action :check_start_date_params, :only => [:company_logs]
  before_action :set_company
  before_action :set_user
  skip_before_filter :verify_authenticity_token
  # include Logging Module
  include Opustime::Logs::System
  include Opustime::Logs::Quickbooks
  include Opustime::Logs::Transaction
  include Opustime::Logs::Admin

  def system_logs
  end

  def companies_list
    render :json => all_companies
  end

  def company_user_list
    render :json => company_associated_users(@company)
  end

  def company_logs
    # total_page, total_record, response = sys_logs(params[:company_id], params[:user_id].present? ? params[:user_id] : nil, params[:page_no], params[:per_page], params[:start_date], params[:end_date].present? ? params[:end_date] : nil)

    total_page, total_record, response = sys_logs(@company, @user, params[:page_no], params[:per_page], params[:start_date], params[:end_date].present? ? params[:end_date] : nil)
    render :json => {:flag => true, :total_page => total_page, :total_record => total_record, :data => response}
  end


  def quickbooks_logs
    total_page, total_record, response = qbo_logs(@company, params[:page_no], params[:per_page], params[:start_date], params[:end_date].present? ? params[:end_date] : nil)
    render :json => {:flag => true, :total_page => total_page, :total_record => total_record, :data => response}
  end

  def transaction_logs
    total_page, total_record, response = tx_logs(@company, params[:page_no], params[:per_page], params[:start_date], params[:end_date].present? ? params[:end_date] : nil)
    render :json => {:flag => true, :total_page => total_page, :total_record => total_record, :data => response}
  end

  def administration_logs
    total_page, total_record, response = admin_logs(params[:page_no], params[:per_page], params[:start_date], params[:end_date].present? ? params[:end_date] : nil)
    render :json => {:flag => true, :total_page => total_page, :total_record => total_record, :data => response}
  end

  private

  # def check_start_date_params
  #   status, message = validate_date_format(params[:start_date])
  #   render :json => {:flag => false, :message => 'Start date is required.'} and return if params[:start_date].blank?
  #   # render :json => {:flag => false, :message => message} and return if !status
  # end

  def set_company
    @company = Company.find_by_id(params[:company_id])
  end

  def set_user
    @user = User.find_by_id(params[:user_id])
  end

end
