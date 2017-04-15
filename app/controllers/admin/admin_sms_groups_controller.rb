class Admin::AdminSmsGroupsController < ApplicationController
  layout "application_admin"
  before_action :admin_authorize
  skip_before_filter :verify_authenticity_token

  before_action :sms_group, only:[:edit, :update, :destroy]
  def index
    @sms_groups = SmsGroup.all
  end

  def new
    @sms_group = SmsGroup.new
    @countries = JSON.parse(File.read("#{RAILS_ROOT_PATH}/config/countries.json"))
    exist_countries = SmsGroupCountry.all.map(&:country)
    @countries = @countries.select {|country| !exist_countries.include? country["code"] }
  end



  def create
    countries = params[:countries]
    req_params = sms_group_params
    req_params.delete(:countries)
    sms_group = SmsGroup.new(req_params)
    if sms_group.save
      if countries.present?
        countries.each do |country|
          sms_group.sms_group_countries.create!(country: country)
        end
      end
      respond_to do |format|
        format.html { redirect_to admin_sms_groups_path, notice: 'SMS Group has been created successfully!' }
      end
    end
  end

  def edit
    @sms_group_countries = @sms_grp_countries.map(&:country)
    @countries = JSON.parse(File.read("#{RAILS_ROOT_PATH}/config/countries.json"))
    exist_countries = SmsGroupCountry.where.not(sms_group_id: params[:id]).map(&:country)
    @countries = @countries.select {|country| !exist_countries.include? country["code"] }
    # raise @sms_group_countries.inspect
  end

  def update
    countries = params[:countries]
    req_params = sms_group_params
    req_params.delete(:countries)
    if @sms_group.update_attributes(sms_group_params)
      if countries.present?
        @sms_grp_countries.each {|country| country.delete}
        countries.each do |country|
          @sms_group.sms_group_countries.create!(country: country)
        end
      end
      respond_to do |format|
        format.html { redirect_to admin_sms_groups_path, notice: 'SMS Group has been updated successfully!.' }
      end
    end
  end

  def destroy
    if @sms_group.destroy
      respond_to do |format|
        format.html { redirect_to admin_sms_groups_path, notice: 'SMS Group has been deleted successfully!' }
      end
    end

  end

  private

  def sms_group_params
    params.require(:sms_group).permit(:id, :name, :incoming_sms, :countries)
  end

  def sms_group
    @sms_group = SmsGroup.find(params[:id])
    @sms_grp_countries = @sms_group.sms_group_countries
  end

end