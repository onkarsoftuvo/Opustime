class AuthenticationController < ApplicationController
  include ApplicationHelper

  respond_to :json
  skip_before_filter :verify_authenticity_token, :only => :login


  def sign_in
    @user = User.new
  end

  # Checking how many accounts exist with this email
  def check_account_existance
    unless params[:email].nil?
      companies = Company.select('companies.id , companies.company_name').joins(:users).where(['users.email=? AND users.acc_active = ? AND companies.status = ?', params[:email] , true , true ]).uniq
    else
      companies = []
    end
    if companies.length == 0
      render :json => {company_exist: false, count: 0}
    elsif companies.length == 1
      cookies[:email] = params[:email] unless params[:email].nil?
      company = companies.first
      login_path = get_redirect_path(company , '/#!/login')
      render :json => {company_exist: true, count: companies.length , email: params[:email] , login_path: login_path  }
    else
      cookies[:email] = params[:email] unless params[:email].nil?
      render :json => {company_exist: true, count: companies.length}
    end

  end

  def search_account
    unless params[:email].nil?
      companies = Company.select('companies.id , companies.company_name').joins(:users).where(['users.email=? AND users.acc_active = ? AND companies.status = ?', params[:email] , true , true ]).uniq
    else
      companies = []
    end
    result = []
    companies.each do |comp|
      item = {}
      item[:comp_id] = comp.id
      item[:name] = comp.company_name
      result << item
    end
    render :json => {account: result}
  end


  def search_company
    #@company = Company.new
    company = Company.find_by_id(params[:comp_id])
    if company.try(:email).to_s == cookies[:email]
      render :json => {comp_id: company.id , flag: true }
    else
      company_email = Company.new
      company_email.errors.add(:email, 'Invalid Email !')
      show_error_json(company_email.errors.messages)
    end
  end

  def get_subdomain
    company = Company.find_by_id(params[:comp_id])
    login_path = get_redirect_path(company , '/#!/login')
    render :json => { login_path: login_path  , flag: true , email: cookies[:email] }
  end

  def login
    begin
      if params[:email].present? && params[:password].present? && request.subdomain.present? && !(request.subdomain.include?('.'))
        username_or_email = params[:email]
        password = params[:password]
        company = Company.where('lower(company_name) = ? OR lower(company_name) = ? ', request.subdomain.gsub('www.','').downcase , request.subdomain.gsub('www.','').downcase.gsub('-', ' ')).first  rescue nil
        unless company.nil?
          if username_or_email.include?('@')
            email = username_or_email
            user = company.users.authenticate_by_email(email, password)
          else
            username = username_or_email
            user = company.users.authenticate_by_email(email, password)
          end
          #  code for finding of attempting login ip
          client_ip = request.remote_ip
          attempt_obj = company.attempts.find_or_create_by(ip_address: client_ip, login_fail_date: Date.today , email: params[:email] )
        end

        respond_to do |format|
          if attempt_obj.login_fail_count >= 10
            @result = {flag: nil, msg: 'Sorry, there have been more than 10 failed login attempts for this account. It is temporarily blocked. Try again 24 hours.'}
            format.any(:xml, :json) { render request.format.to_sym => @result }
          else
            if user && user.acc_active
              log_in user

              if params[:remember_me]
                remember(user)
              else
                forget(user)
              end
              @result = {flag: true, user_id: user.id, :is_2factor_auth_enabled => user.auth_factor}
              format.any(:xml, :json) { render request.format.to_sym => @result }
            else
              attempt_obj.update(login_fail_count: attempt_obj.login_fail_count + 1)
              @result = {flag: false}
              format.any(:xml, :json) { render request.format.to_sym => @result }
            end
          end
        end
      else
        if request.subdomain.include?('.')
          request.subdomain.split('.').each do |sub_domain_name|
            company = Company.where('lower(company_name) = ?', sub_domain_name.split('.')[0].gsub('www.','').downcase).first  rescue nil
            break unless company.nil?
          end
          login_path = get_redirect_path(company , '/#!/login')
          @result = {flag: false , login_path: login_path}
        else
          @result = {flag: false}
        end
        render :json => @result
      end
    rescue Exception => e
      render :json => {flag: false}
    end
  end


#   method to get session at front end 
  def get_session
    begin
      if session[:user_id].present? && session[:user_name].present? && current_user.present?
        unless session[:comp_id].present?
          @result = {flag: true, :is_2factor_auth_enabled => session[:is_2factor_auth_enabled], :google_authenticator_session => session[:google_authenticator_session], session_id: session[:user_id], :user_name => session[:user_name], :is_trial => session[:is_trial], :is_subscribed => session[:is_subscribed]}
        else
          @result = {flag: true, :is_2factor_auth_enabled => session[:is_2factor_auth_enabled], :google_authenticator_session => session[:google_authenticator_session], session_id: session[:user_id], :user_name => session[:user_name], :comp_id => session[:comp_id], :is_trial => session[:is_trial], :is_subscribed => session[:is_subscribed]}
        end
        render :json => @result
      else
        reset_session
        @result = {flag: false}
        render :json => @result
      end
    rescue Exception => e
      reset_session
      @result = {flag: false}
      render :json => @result
    end

  end

  def signed_out
    log_out if logged_in?
    render :json => {flag: false}
  end

  def home_page
    unless request.subdomain.nil?
      login_path =  request.original_url.gsub(request.subdomain.to_s + '.' , '').gsub('/home_page' , '/#!/login_first')
    else
      login_path =  request.original_url.gsub('/home_page' , '/#!/login_first')
    end
    render :json => {home_path: login_path }
  end

  def get_login_email
    render :json=> { username: cookies[:email] }
  end

  private

  def get_redirect_path(company , sub_path)
    coming_path = request.base_url.sub(/^www\./, '')
    coming_path = coming_path.gsub(request.subdomain , company.company_name.to_s.downcase) if request.subdomain.include?('.')
    requested_path = URI.parse(request.base_url).host
    splitted_path = coming_path.split('//')
    # if requested_path.split('.').length <= 2
    #   login_path = splitted_path[0] + '//' + company.company_name.to_s.downcase.gsub(' ','-') + '.' + splitted_path[1] + sub_path
    # else
    #   login_path = splitted_path[0] + '//' + splitted_path[1] + sub_path
    # end


    if requested_path.split('.').length <= 3
      if requested_path.split('.').length <= 2
        login_path = splitted_path[0] + '//' + company.company_name.to_s.downcase.gsub(' ','-') + '.' + splitted_path[1] + sub_path
      elsif requested_path.split('.').length == 3
        split_path = splitted_path[1].split('.')
        path = split_path[1] + '.'+ split_path[2]
        login_path = splitted_path[0] + '//' + company.company_name.to_s.downcase.gsub(' ','-') + '.' + path + sub_path
      else
        login_path = splitted_path[0] + '//' + splitted_path[1] + sub_path
      end
    end

  end


end
