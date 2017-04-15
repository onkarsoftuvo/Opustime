class Admin::Owners::RegistrationsController < Devise::RegistrationsController
  layout 'admin_form'
  after_action :clear_sign_up_cookies, :only => [:new]
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    build_resource(configure_sign_up_params)
    if resource.role.present? && !have_duplicate_email?(resource)
      AdminMailer.sidekiq_delay(:queue => 'admin').welcome_email(resource.id) if resource.save
      if resource.persisted?
        if resource.active_for_authentication?
          # sign_up(resource_name, resource)
          redirect_to new_owner_session_path, :flash => {:info => 'Account created successfully but not active.'}
        end
      else
        set_sign_up_cookies(resource)
        clean_up_passwords resource
        flash[:error] = resource.errors.full_messages.class == Array ? resource.errors.full_messages.first : resource.errors.full_messages
        respond_with resource
      end
    elsif have_duplicate_email?(resource)
      redirect_to new_owner_registration_path, :flash => {:warning => 'Email already taken.'}
    else
      # set_sign_up_cookies(@owner)
      redirect_to new_owner_registration_path, :flash => {:warning => 'Please select your role.'}
    end

  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # You can put the params you want to permit in the empty array.
  def configure_sign_up_params
    params.require(:owner).permit(:first_name, :last_name, :email, :password, :password_confirmation, :role)
  end


  #
  # def configure_sign_up_params
  #   added_attrs_for_sign_up = [:role, :email, :password,:password_confirmation,:first_name,:last_name]
  #   devise_parameter_sanitizer.for(:sign_up) << added_attrs_for_sign_up
  # end

  # You can put the params you want to permit in the empty array.
  def configure_account_update_params
    devise_parameter_sanitizer.for(:account_update) << :attribute
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   # redirect_to new_owner_session_path, :flash => {:info => 'Account created successfully but not active.'}
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  def have_duplicate_email?(owner)
    return Owner.where(:email => owner.email).count > 0 ? true : false
  end

  def set_sign_up_cookies(owner)
    cookies[:sign_up] = YAML::dump({'first_name' => owner.first_name, 'last_name' => owner.last_name, 'email' => owner.email})
  end


  def clear_sign_up_cookies
    cookies.delete :sign_up
  end


end
