class PasswordResetsController < ApplicationController
  respond_to :json 
  skip_before_filter :verify_authenticity_token

  def new 
    
  end
  
  def create
    company = Company.where('lower(company_name) = ? OR lower(company_name) = ? ', request.subdomain.gsub('www.','').downcase , request.subdomain.gsub('www.','').downcase.gsub('-', ' ')).first  rescue nil
    if company.present?
      user= User.where(:email => params[:email], :company_id => company.id).first
    else
      user = User.find_by_email(params[:email]) rescue nil
    end
    if user
      user.send_password_reset
      ResetpasswordsWorker.perform_async(user.id)
      render :json=>{flag: true }
    else
      render :json=>{flag: false  }
    end
  end
  
  

  def edit
    @user = User.find_by_password_reset_token!(params[:id]) rescue nil
    unless @user.nil?
      render :json=> {:password_flag=> true , :id=> params[:id]}
    else
      render :json=> {:password_flag=> false}
    end
  end

  def update
    if params[:user].blank?
      params[:user][:password]=nil
      params[:user][:password_confirmation]=nil
    end
    @user = User.find_by_password_reset_token!(params[:id]) rescue nil
    unless @user.nil?
      result = {}
      if @user.password_reset_sent_at < 2.hours.ago
        @user.errors.add(:password_token , "has been expired.")
        show_error_json(@user.errors.messages)
      elsif
        @user.update_attribute(:password, params[:user][:password])
        @user.update_attributes(password_reset_token: nil, password_reset_sent_at: nil)
        result = {:password_flag=> true ,  :msg=> "password has been changed successfully."}
        render :json=> result
      else
        if @user.nil?
          user = User.new
          user.errors.add(:user , "not found ! ")
          show_error_json(user.errors.messages)
        else
          show_error_json(@user.errors.messages)
        end
      end
    else
      user = User.new
      user.errors.add(:password , "has been reset as before.")
      show_error_json(user.errors.messages)
    end
    
  end

end
