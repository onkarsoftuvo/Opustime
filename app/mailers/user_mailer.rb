class UserMailer < ActionMailer::Base
  default from: 'no-reply@opustime.com'
  include PlivoSms

  def welcome_email(user, password)
    @user = user
    @url = 'http://app.opustime.com'
    @password = password
    mail(to: @user.email, subject: 'Welcome to OpusTime')
  end

  def password_reset(user)
    @user = user
    @domain_path = "http://app.opustime.com"
    mail :to => user.email, :subject => "Password Reset"
  end

  def google_authenticator_qr_code(user_id)
    @user = User.find_by_id(user_id)
    @code = @user.otp_code
    # @qr = RQRCode::QRCode.new(@user.google_qr_url, :size => 8, :level => :h )
    @domain_path = "http://app.opustime.com"
    attachments.inline['logo.jpg'] =  File.read( Rails.root.join("app", "assets/images/logo.jpg"))
    mail :to => @user.email, :subject => 'Authenticator OTP Code'
  end

  def send_otp_code_via_sms(user_id)
    user = User.find_by_id(user_id)
    code = user.otp_code
    src_no = user.company.sms_number.try(:number) || SMS_TRIAL_NO[:stage]
    accurate_no = user.phone
    unless src_no.nil? || accurate_no.nil?
      sms_body = "OTP code is #{code}"
      plivo_instance = PlivoSms::Sms.new
      response = plivo_instance.send_sms(src_no , accurate_no , sms_body)
      unless [200 , 202].include?response[0]
        plivo_instance.send_sms(SMS_TRIAL_NO[:stage] , accurate_no , sms_body)
      end
    end
  end

end
