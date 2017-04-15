class Admin::AdminController < ApplicationController
  include AdminHelper
  layout 'application_admin'
  #respond_to :json 
  before_action :admin_authorize, :only => [:view]
  before_action :find_company, :only => [:view]
  # after_action :clear_sign_up_cookies, :only => [:sign_up]
  # skip_before_action :verify_authenticity_token, :only => [:login]

  def view

  end

  # def sign_in
  # end
  #
  # def sign_out
  #   reset_session
  #   redirect_to '/admin/sign_in', :flash => {:success => 'Logged out!'}
  # end

  # def login
  #   # for Admin User =>'0'
  #   if params[:user_type].to_s.eql?('0')
  #     login_status = authenticate_admin_user
  #     login_redirection(login_status)
  #     # for Sale User =>'1'
  #   elsif params[:user_type].to_s.eql?('1')
  #     login_status = authenticate_sales_user
  #     login_redirection(login_status)
  #     # for Marketing User =>'2'
  #   elsif params[:user_type].to_s.eql?('2')
  #     login_status = authenticate_marketing_user
  #     login_redirection(login_status)
  #   else
  #     # for Super Admin User
  #     login_status = authenticate_super_admin
  #     login_redirection(login_status)
  #   end
  #
  # end

  # def create_user
  #   @owner = Owner.new(owner_params)
  #   @owner.user_type = params[:owner][:user_type]
  #   @owner.role = assign_new_role(@owner.user_type)
  #   if params[:owner][:user_type].present? && !have_duplicate_email?(@owner)
  #     session[:owner_id] = @owner.save ? @owner.id : nil
  #
  #     session[:owner_role] = @owner.role rescue nil
  #     sign_up_redirection(@owner)
  #   elsif session[:duplicate_email]
  #     set_sign_up_cookies(@owner)
  #     redirect_to admin_signup_path, :flash => {:warning => 'Email already taken.'}
  #   else
  #     set_sign_up_cookies(@owner)
  #     redirect_to admin_signup_path, :flash => {:warning => 'Please select your role.'}
  #   end
  #
  # end

  # def sign_up
  #   @owner = Owner.new
  # end

  def find_company
    @company = Company.all
  end

  private

  #
  # def owner_params
  #   params.require(:owner).permit(:first_name, :last_name, :email, :role, :password, :password_confirmation, :status)
  # end

  # def find_layout
  #   case action_name
  #     when "sign_in"
  #       "admin_form"
  #     when "sign_up"
  #       "admin_form"
  #     when "create_user"
  #       "admin_form"
  #     else
  #       "application_admin"
  #   end
  # end

  # def login_redirection(login_status)
  #
  #   if login_status.to_s.eql?('1')
  #     redirect_to '/admin/sign_in', :flash => {:info => 'Your account is not active'}
  #   elsif login_status.to_s.eql?('2')
  #     redirect_to '/admin/sign_in', :flash => {:error => 'Your email or password is incorrect.'}
  #   else
  #     redirect_to admin_panel_view_path
  #   end
  # end
  #
  # def sign_up_redirection(owner)
  #   if owner.errors.any?
  #     set_sign_up_cookies(owner)
  #     render 'admin/admin/sign_up'
  #   else
  #     AdminMailer.sidekiq_delay(:queue => 'admin').welcome_email(owner.id)
  #     reset_session
  #     redirect_to '/admin/sign_in', :flash => {:info => 'Account created successfully but not active.'}
  #   end
  # end
  #
  # def set_sign_up_cookies(owner)
  #   cookies[:sign_up] = YAML::dump({'first_name' => owner.first_name, 'last_name' => owner.last_name, 'email' => owner.email})
  # end
  #
  # def clear_sign_up_cookies
  #   cookies.delete :sign_up
  # end

end
  