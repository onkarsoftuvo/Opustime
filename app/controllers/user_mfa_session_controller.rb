class UserMfaSessionController < ApplicationController
  skip_before_action :verify_authenticity_token
  include PlivoSms

  def create

    if current_user.authenticate_otp(params[:mfa_code].to_s, drift: 5*60)
      # create new google authenticator session
      session[:google_authenticator_session] = true
      render :json => {:flag => true, :google_authenticator_session => check_google_authenticator_session}
    else
      render :json => {:flag => false, :google_authenticator_session => check_google_authenticator_session}
    end
  end

  def resend_qr_code
    user = User.find_by_id(session[:user_id])
    # regenerate new google authenticator QR code
    if user.present?
      # generate new google secret token
      user.update_columns(:google_secret=>ROTP::Base32.random_base32)
      # generate new google QR code uri
      user.update_columns(:google_qr_url => user.provisioning_uri(user.email, issuer: 'Opustime'))
      # resend new QR code to user for Scanning using Google Authenticator App
      UserMailer.sidekiq_delay.google_authenticator_qr_code(user.id)
      UserMailer.sidekiq_delay.send_otp_code_via_sms(user.id)
      render :json => {:flag => true} and return
    else
      render :json => {:flag => false} and return
    end
  end


end
