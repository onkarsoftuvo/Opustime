class AdminMailer < ActionMailer::Base
  default from: 'no-reply@opustime.com'

  def welcome_email(user_id)
    @user = Owner.find_by_id(user_id)
    @account_type = if @user.role.to_s.eql?('admin_user') then
                      'admin'
                    else
                      @user.role.to_s.eql?('sales_user') ? 'sales' : 'marketing'
                    end
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: @user.email, subject: 'Welcome to OpusTime Admin Panel')
  end

  def active_or_inactive(user_id)
    @user = Owner.find_by_id(user_id)
    @account_type = if @user.role.to_s.eql?('admin_user') then
                      'Admin'
                    else
                      @user.role.to_s.eql?('sales_user') ? 'Sales' : 'Marketing'
                    end

    @domain_path = "http://app.opustime.com"
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    if @user.status
      mail :to => @user.email, :subject => "#{@account_type} Account Activation"
    else
      mail :to => @user.email, :subject => "#{@account_type} Account Deactivation"
    end
  end

  def delete_account(user_id)
    @user = Owner.find_by_id(user_id)
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: @user.email, subject: 'Admin Account Deleted')
  end

end
