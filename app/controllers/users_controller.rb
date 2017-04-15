class UsersController < ApplicationController
  include UsersHelper
  include Opustime::Utility

  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain, :only => [:index, :new, :create, :get_appointment_type_list, :update, :all_practitioners , :sms_items , :logo_upload , :generate_ical_event]
  before_action :find_user, :only => [:edit, :update , :sms_items , :logo_upload , :generate_ical_event]
  before_action :set_params_in_format, :only => [:create, :update]

  # using only for postman to test API. Remove later
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  load_and_authorize_resource  param_method: :user_params , only: [:index]
  before_filter :load_permissions

  def index
    begin
      users = @company.users.active_user.select("users.id , users.first_name,users.title, users.last_name , users.is_doctor , users.role")
      render :json => users
    rescue Exception => e
      render :json => {error: e.message}
    end
  end

  def all_practitioners
    doctors = @company.users.doctors.select("id , title , first_name , last_name")
    result = []
    doctors.each do |doctor|
      item = {}
      item[:id] = doctor.id
      item[:full_name] = doctor.full_name
      result << item
    end
    render :json => {practitioners: result}
  end

  def new
    begin

     authorize! :manage_other  , User

      user_object = @company.users.build
      user_info = user_object.build_practi_info
      user_info.default_type="N/A"
      user_refer = user_object.practi_refers.build
      user_avail = user_object.practitioner_avails.build
      user_day = user_avail.days.build
      user_break = user_day.practitioner_breaks.build
      result = get_user_instance(user_object, user_info, user_refer, user_avail, user_day, user_break)
      render :json => {user: result}
    rescue Exception => e
      render :json => {user: result}
    end
  end

  def create
    authorize! :manage_other  , User
    max_doctor = @company.subscription.doctors_no
    avail_doctor = @company.users.doctors.count
    # check subscribed plan to create user
    if user_params[:is_doctor]
      if (avail_doctor < max_doctor)
        unless @company.users.map(&:email).include?(user_params[:email])
          create_new_user(user_params)
        else
          user = User.new
          user.errors.add('Email', 'already has been taken')
          show_error_json(user.errors.messages)
        end
      else
        user = User.new
        user.errors.add("user", "can't be added.out of subscribed plan!")
        show_error_json(user.errors.messages)
      end
    else
      unless @company.users.map(&:email).include?(user_params[:email])
        create_new_user(user_params)
      else
        user = User.new
        user.errors.add('Email', 'already has been taken')
        show_error_json(user.errors.messages)
      end

    end
  end


  def edit
    unless current_user == @user
      authorize! :manage_other  , User
    else
      authorize! :view_own  , User
    end

    result = {}
    result = get_user_info_for_edit(@user) unless @user.nil?

    render :json => result
  end

  def update
    if current_user == @user
      authorize! :edit_own  , User
    else
      authorize! :manage_other  , User
    end
    # Adding destroy- true in params for deleteable breaks
    max_doctor = @company.subscription.doctors_no
    avail_doctor = @company.users.doctors.count

    if user_params[:is_doctor]
      if ((avail_doctor < max_doctor) || (@user.is_doctor))
        unless @company.users.where(['users.id != ?',user_params[:id]]).map(&:email).include?(user_params[:email])
          update_existing_user(params)
        else
          user = User.new
          user.errors.add('Email', 'already has been taken')
          show_error_json(user.errors.messages)
        end

      else
        user = User.new
        user.errors.add("user", "can't be added.out of subscribed plan!")
        show_error_json(user.errors.messages)
      end
    else
      unless @company.users.where(['users.id != ?',user_params[:id]]).map(&:email).include?(user_params[:email])
        update_existing_user(params)
      else
        user = User.new
        user.errors.add('Email', 'already has been taken')
        show_error_json(user.errors.messages)
      end
    end
  end

  #   Update functionality for file upload
  def logo_upload
    if current_user == @user
      authorize! :edit_own  , User
    else
      authorize! :manage_other  , User
    end

    logo = params[:file]
    @user.update(:logo=> logo) unless logo.blank?
    if @user.valid?
      render :json=> {flag: true}
    else
      show_error_json(@user.errors.messages)
    end
  end

  # def destroy
  # user = User.find(params[:id])
  # if user.destroy
  # render :json=>{flag: true}
  # else
  # show_error_json(user.errors.messages , flag= false)
  # end
  # end

  def get_appointment_type_list
    apptment_types = @company.appointment_types.select("appointment_types.id ,appointment_types.name , appointment_types.color_code")
    result = []
    apptment_types.each do |appnt|
      appnt_list = {}
      appnt_list[:appointment_type_id] = appnt.id
      appnt_list[:name] = appnt.name
      appnt_list[:is_selected] = false
      result << appnt_list
    end
    render :json => result
  end

  def check_security_role
    result = {}
    result[:view_own] = can? :view_own , User
    result[:view_edit] = can? :edit_own , User
    result[:manage_others] = can? :manage_other , User
    result[:logged_in_user_id] = current_user.try(:id)

    render :json => result
  end

  def sms_items
    result = {}
    unless @user.nil?
      result[:id] = @user.id
      result[:name] = @user.full_name
      result[:number] = @user.get_primary_contact
      result[:conversation] = @user.get_previous_conversations
    end

    render :json => result
  end

  def permission_matrix
    render :json =>  Owner.permission_matrix
  end

  def generate_ical_event

    respond_to do |format|
      format.html
      format.ics do
        calendar = Icalendar::Calendar.new
        user = @company.users.find_by_id(params[:id])
        unless user.nil?
          @appnts = user.appointments.active_appointment.where(["(Date(appnt_date) >= ? AND appnt_time_start  > CAST(?  AS time) AND status= ?) OR (Date(appnt_date) > ? AND status= ?) ", Date.today , Time.now  , true, Date.today , true]).order("appnt_date asc")
          @appnts.each do |appnt|
            calendar.add_event(appnt.to_ics)
          end
        end
        calendar.publish
        render :text => calendar.to_ical
      end
    end
  end


  def update_language
    @user = current_user.update(:language => params[:lang])
    session[:locale] = params[:lang]
    render :text => true
  end

  private

  def user_params
    params.require(:user).permit(:id, :title, :first_name, :last_name, :email, :is_doctor, :phone, :time_zone, :auth_factor, :role, :acc_active, :password, :password_confirmation , :appointment_types_users_attributes => [:id, :appointment_type_id, :_destroy],
                                 :practi_info_attributes => [:id, :designation, :desc, :default_type, :notify_by, :cancel_time, :is_online, :allow_external_calendar,
                                                             :practi_refers_attributes => [:id, :ref_type, :number, :business_id, :_destroy],
                                                             :practitioner_avails_attributes => [:id, :business_id, :business_name,
                                                                                                 :days_attributes => [:id, :day_name, :start_hr, :start_min, :end_hr, :end_min, :is_selected,
                                                                                                                      :practitioner_breaks_attributes => [:id, :start_hr, :start_min, :end_hr, :end_min, :_destroy]
                                                                                                 ]
                                                             ]
                                 ])
  end

  def find_user
    @user = User.find(params[:id])
  end

  def set_params_in_format
    if current_user.id == params[:user][:id].to_i
      params[:user].delete "role"
    end
    unless params[:user][:practi_info_attributes].nil?
      params[:user][:appointment_types_users_attributes] = []
      params[:user][:practi_info_attributes][:appointment_services].each do |appnt_service|
        if appnt_service[:is_selected]
          item = {}
          item[:id] = appnt_service[:id] unless appnt_service[:id].nil?
          item[:appointment_type_id] = appnt_service[:appointment_type_id]
          params[:user][:appointment_types_users_attributes] << item
        else
          existing_record = nil
          existing_record = AppointmentTypesUser.find_by_appointment_type_id_and_user_id(appnt_service[:appointment_type_id], params[:user][:id]) rescue nil unless params[:user][:id].nil?
          unless existing_record.nil?
            params[:user][:appointment_types_users_attributes] << {id: existing_record.id, :_destroy => true}
          end
        end
      end unless params[:user][:practi_info_attributes][:appointment_services].nil?
    end
  end

  def update_existing_user(params)
    params[:user][:practi_info_attributes] = nil unless params[:user][:is_doctor]
    manage_deleted_params(params) unless (params[:user][:practi_info_attributes].nil? || params[:user][:practi_info_attributes][:id].nil?)
    @user.assign_attributes(user_params.except(:phone))
    phone_no = PhonyRails.normalize_number(user_params[:phone], country_code: user_country_code(@user))
    phone_no = user_params[:phone]  if phone_no.nil?
    @user.assign_attributes(:phone => phone_no)
    if @user.save
      session[:user_name] = @user.first_name if current_user.id == @user.id
    end
    unless @user.errors.messages.count > 0
      # set 2 factor authentication layer
      set_2factor_authentication(@user)
      result = {flag: true, username: session[:user_name]}
      render :json => result
    else
      show_error_json(@user.errors.messages)
    end
  end

  def create_new_user(user_params)
    user = @company.users.new(user_params)
    user.assign_attributes(:phone => PhonyRails.normalize_number(user_params[:phone], country_code: user_country_code(user)))
    if user.save
      unless user.errors.any?
        # It is adding for  choices on patient module
        user.create_client_filter_choice(appointment: true, treatment_note: true, invoice: true, payment: true, attached_file: true, letter: true, communication: true, recall: true) unless user.role.casecmp("bookkeeper") == 0
        set_2factor_authentication(user)
        # Sending password to created user
        UsersWorker.perform_async(user.id, user.temp_password)
        result = {flag: true, id: user.id}
        render :json => result
      else
        user.errors.add(:break, "does not exist in available time")
        show_error_json(user.errors.messages)
      end
    else
      show_error_json(user.errors.messages)
    end
  end

  def set_2factor_authentication(user)
    if user.auth_factor
      if user.google_secret.blank?
        # generate new google secret token
        user.update_columns(:google_secret=>ROTP::Base32.random_base32)
        # generate new google QR code uri
        user.update_columns(:google_qr_url => user.provisioning_uri(user.email, issuer: 'Opustime'))
        session[:is_2factor_auth_enabled] = user.auth_factor if user.id.to_s.eql?(session[:user_id].to_s)
        # send new QR code to user for Scanning using Google Authenticator App
        UserMailer.sidekiq_delay(:queue=>'mailer').google_authenticator_qr_code(user.id)
      end
    else
      # reset google credentials
      user.update_columns(:google_secret => nil, :google_qr_url => nil, :auth_factor => false)
      # reset 2factor authentication value in session
      session[:is_2factor_auth_enabled] = false if user.id.to_s.eql?(session[:user_id].to_s)
      # reset google authenticator session
      # UserMfaSession::destroy
      session[:google_authenticator_session] = nil
    end

  end

end
