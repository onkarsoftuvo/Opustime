class Admin::Owners::SessionsController < Devise::SessionsController
  layout 'admin_form'
  skip_before_action :verify_authenticity_token, :only => [:create]

  # before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    owner = params[:owner][:role].present? ? Owner.find_by(email: params[:owner][:email], role: params[:owner][:role]) : Owner.find_by(email: params[:owner][:email],role: 'super_admin_user')
    resource,login_status = authentication(owner, params[:owner][:password])
    login_redirection(login_status,resource)

  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
    redirect_to new_owner_session_path,:flash => {:success => 'Logged out!'}
  end

  protected

  def login_redirection(login_status,resource)

    if login_status.to_s.eql?('1')
      redirect_to new_owner_session_path, :flash => {:info => 'Your account is not active'}
    elsif login_status.to_s.eql?('2')
      redirect_to new_owner_session_path, :flash => {:error => 'Your email or password is incorrect.'}
    else
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  def authentication(owner, password)
    # Return 0 if authenticated , 1 if account is not active ,
    # 2 if not authenticated
    if owner && owner.valid_password?(password)

      if owner.status
        self.resource = warden.authenticate!(auth_options)
        self.resource = owner
        sign_in owner, :bypass => true
        return resource,0
      else
        return resource,1
      end
    else
      return nil,2
    end
  end

end
