class ApplicationController < ActionController::Base
  # include Quickbooks::Session
  include CanCan::ControllerAdditions
  include PublicActivity::StoreController
  include Opustime::Utility

  protect_from_forgery with: :exception
  helper_method :current_user
  helper_method :current_owner
  before_action :find_company, :if => Proc.new { controller_name != 'admin' && current_user.present? }
  before_action :set_qbo_credentials, :if => Proc.new { controller_name != 'admin' } && :company_login?
  before_action :set_global_current_user, :if => Proc.new { controller_name != 'admin' && current_user.present? }
  before_action :set_global_company, :if => Proc.new { controller_name != 'admin' && @company.present? }
  around_filter :set_time_zone, :if => Proc.new { controller_name != 'admin' && current_user.present? }


  # before_action :redirect_to_https 
  before_filter :set_locale
  # before_filter :redirect_to_https
  # rescue_from ActiveRecord::RecordNotFound, with: :current_user


  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.info "========================> Controller - #{controller_name} action_name - #{action_name}"
    render :json => {:code => 401, :error => exception.message}
  end

  def redirect_to_https
    redirect_to :protocol => "https://" unless request.ssl?
  end

  def company_login?
    # return false if Admin panel is open
    if controller_name == 'admin'
      false
    else
      session.present? && session['comp_id'].present? ? true : false
    end
  end

  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  def cities
    render json: CS.cities(params[:state], :in).to_json
  end

  def after_sign_in_path_for(resource)
    home_admin_dashboards_path
  end


=begin
  def admin_authorize
    puts"==admin_authorize======"

    unless owner_signed_in?
      redirect_to new_owner_session_path
    else
      unless current_owner.nil? || current_owner.role.eql?('super_admin_user')
        @admin_user_permission = current_owner.user_role.admin_permission
      else
        @admin_user_permission = nil
      end
    end
  end
=end

  def admin_authorize
    if owner_signed_in?
      unless current_owner.nil? || current_owner.role.eql?('super_admin_user')
        @admin_user_permission = current_owner.user_role.admin_permission
      else
        @admin_user_permission = nil
      end
    else
      redirect_to new_owner_session_path
    end
  end

  def authorize
    redirect_to '/' unless current_user
  end

  def log_in(user)
    session[:user_id] = user.id
    session[:user_name] = user.first_name
    session[:comp_id] = user.company.id
    session[:is_2factor_auth_enabled] = user.auth_factor
    session[:is_trial] = user.company.subscription.is_trial
    session[:is_subscribed] = user.company.subscription.is_subscribed
    user.company.update_columns(:lastlogin => Time.now)
  end


  def find_company
    @company = Company.find(session["comp_id"]) rescue nil unless session["comp_id"].nil?
  end

  # def is_2factor_authentication_enabled?
  #   return current_user.auth_factor ? true : false if current_user.present?
  # end

  # Get login Company Quickbooks Credentials for QBO data Syn
  def set_qbo_credentials
    # find company
    unless ["admin", "log", "admin_profile", "business_report", "financial_report", "trial_user", "admin_notification", "admin_subscription", "admin_sms", "admin_sms_setting", "admin_other", "admin_companies", "admin_business", "admin_patients" "permission"].include? controller_name
      #unless params[:controller] == "admin/business_report"
      company = find_company
      unless company.nil?
        qbo_credentials = company.quick_book_info rescue nil
        qbo_credentials.present? ?
            set_global(qbo_credentials.token, qbo_credentials.secret, qbo_credentials.realm_id, qbo_credentials, company) :
            set_global(nil, nil, nil, nil, nil)
      end
    end
  end

  def find_company_by_sub_domain
    @company = Company.where('lower(company_name) = ? OR lower(company_name) = ?', request.subdomain.try(:downcase).gsub('-',' ') , request.subdomain.try(:downcase)).first  rescue nil
  end

  def find_company_for_booking
    @company = Company.find_by_id(params[:comp_id]) rescue nil if @company.nil?
  end


  protected

  # changes for permission matrix

  #derive the model name from the controller. egs UsersController will return User
  def self.permission
    return name = self.name.gsub('Controller', '').singularize.split('::').last.constantize.name rescue nil
  end

  def current_ability
    @current_ability ||= Ability.new(current_user) unless current_user.nil?
  end

  #load the permissions for the current user so that UI can be manipulated
  def load_permissions
    @current_permissions = current_user.user_role.permissions.collect { |i| [i.subject_class, i.action] } unless current_user.nil?
  end


  def id_format(obj)
    "0"*(6-obj.id.to_s.length)+ obj.id.to_s
  end

  def treatment_note_view(treatment_notes, date_wise_event)
    treatment_notes.each do |note|
      item = {}
      item[:id] = note.id
      # item[:template_id] = note.template_id
      user = User.find(note.created_by_id) rescue nil
      item[:created_by] = user.full_name unless user.nil?
      item[:treatment_title] = note.title
      item[:appointment_id] = note.appointment.try(:id)
      item[:practitioner_name] = user.full_name_with_title unless user.nil?
      item[:note_created_at] = note.created_at.strftime("%d %b %Y ,%H:%M %p")
      item[:company_name] = note.template_note.company.company_name rescue nil
      item[:note_last_updated] = note.updated_at.strftime("%d %b %Y ,%H:%M %p")
      item[:treatment_sections_attributes] = []
      sections = note.treatment_sections
      sections.each do |section|
        set_section = {}
        set_section[:id] = section.id
        set_section[:name] = section.name
        set_section[:treatment_questions_attributes] = []
        section.treatment_questions.each do |qs|
          set_qs = {}
          set_qs[:id] = qs.id
          set_qs[:title] = qs.title
          set_qs[:quest_type] = qs.quest_type
          check_box_ans_data = ""
          qs.treatment_quest_choices.each do |choice|
            quest_answer = choice.treatment_answer
            unless ["Text", "Paragraph"].include? qs.quest_type
              unless qs.quest_type =="Multiple_Choice"
                if quest_answer.is_selected
                  check_box_ans_data = check_box_ans_data + choice.title + ","
                end
              end
            else
              check_box_ans_data = quest_answer.ans
            end
          end
          if qs.quest_type.casecmp("Multiple_Choice")==0
            ans_data = nil
            ans_data = qs.treatment_answers.pluck("ans").uniq.compact.first
            set_qs[:ans] = ans_data
          else
            if qs.quest_type.casecmp("Checkboxes")==0
              check_box_ans_data = check_box_ans_data.chomp(",")
              a = check_box_ans_data.gsub(",", " and ")
              set_qs[:ans] = a
            else
              set_qs[:ans] = check_box_ans_data
            end
          end
          set_section[:treatment_questions_attributes] << set_qs
        end
        item[:treatment_sections_attributes] << set_section
      end
      item[:save_final] = note.save_final
      item[:created] = note.created_at.strftime("%d %b %Y")
      item[:last_updated] = note.updated_at.strftime("%d %b %Y") == note.created_at.strftime("%d %b %Y") ? nil : note.updated_at.strftime("%d %b %Y")

      #     security role of logged in to access treatment note

      security_role_item = {}
      security_role_item[:read] = ((can? :view_own, note) || (can? :view_all, note))
      security_role_item[:create] = can? :view_own, note
      security_role_item[:modify] = can? :edit_own, note
      security_role_item[:delete] = can? :delete, note
      security_role_item[:export_pdf] = ((can? :view_own, note) || (can? :view_all, note))
      item[:security_role] = security_role_item


      date_wise_event[:treatment_notes] << item
    end
    return date_wise_event
  end

  def attached_file_type(file_obj)
    str = ""
    case file_obj.avatar.content_type
      when "application/pdf"
        str = "pdf"
      when "application/vnd.ms-excel"
        str = "excel"
      when "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        str = "spreadsheetml"
      when "application/msword"
        str = "msword"
      when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        str = "wordprocessingml"
      when "text/plain"
        str = "text"
      else
        str = "other"
    end
    if file_obj.avatar.content_type.to_s.include? "image"
      str = "image"
    end
    return str
  end

  private

  def set_locale
    I18n.locale =  session[:locale] || I18n.default_locale
  end

  def show_error_json(error_arr, flag= false)
    error_msg = []
    error_arr.keys.each do |key|
      item= {}
      item[:error_name] = key.to_s.split("_").join(" ")
      item[:error_msg] = error_arr[key].first
      error_msg << item
    end
    render :json => {:error => error_msg, :flag => flag}
  end

  # google authenticator session
  def check_google_authenticator_session
    if !set_google_authenticator_session
      return false
    else
      return true
    end
  end


  def set_global(val1, val2, val3, val4, val5)
    $token = val1
    $secret = val2
    $realm_id = val3
    $qbo_credentials = val4
    $company = val5
  end

  # set google authenticator session
  def set_google_authenticator_session
    google_authenticator_session = session[:google_authenticator_session].present? ? session[:google_authenticator_session] : false
    return google_authenticator_session

    #
    # google_authenticator_session = (user_mfa_session = UserMfaSession.find) && (user_mfa_session ? user_mfa_session.record == current_user : !user_mfa_session)
    # session[:google_authenticator_session] = google_authenticator_session.present? ? google_authenticator_session : false
    # return google_authenticator_session
  end

  # set global timeZone
  def set_time_zone(&block)
    time_zone = timeZone_lookup(current_user.try(:time_zone))
    Time.use_zone(time_zone, &block)
  end

  def set_global_current_user
    $current_user = current_user
  end

  def set_global_company
    $company = @company
  end


end
