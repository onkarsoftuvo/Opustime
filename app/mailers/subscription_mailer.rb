class SubscriptionMailer < ActionMailer::Base
  default from: 'no-reply@opustime.com'

  def new_subscription(company_id)
    @company = Company.find_by_id(company_id)
    @subscription = @company.subscription
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: @company.account.email, subject: 'New Subscription Purchased')
  end

  def cancel_subscription(company_id)
    @company = Company.find_by_id(company_id)
    @subscription = @company.subscription
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: @company.account.email, subject: 'Subscription Cancelled')
  end

  def low_to_high_plan_change(company_id)
    @company = Company.find_by_id(company_id)
    @subscription = @company.subscription
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: @company.account.email, subject: 'Plan switch from  Low to High cost')
  end

  def high_to_low_plan_change(company_id)
    @company = Company.find_by_id(company_id)
    @subscription = @company.subscription
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: @company.account.email, subject: 'Plan switch from High to Low cost')
  end

  def trial_subscription(company_id)
    @company = Company.find_by_id(company_id)
    @subscription = @company.subscription
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: @company.email, subject: 'Opustime Account Notification')
  end

  def days_left_subscription_expiry(company, no_of_days)
    @no_of_days = no_of_days
    send_to_email = company.try(:account).try(:email) || company.email
    @subscription = company.subscription
    @subscription_type = @subscription.is_trial ? 'trial' : 'Renew'
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    if @subscription_type.to_s.eql?('trial')
      mail_subject = "#{no_of_days.to_s} #{'day'.pluralize(no_of_days.to_i)} left to expire #{@subscription_type} plan Subscription"
    else
      mail_subject = "#{no_of_days.to_s} #{'day'.pluralize(no_of_days.to_i)} left to auto renew #{@subscription.name} plan Subscription"
    end
    mail(to: send_to_email, subject: mail_subject)
  end

  def auto_payment_by_wallet(company_id, payment_type)
    # if payment_type=> 1 then fully_wallet_payment
    # if payment_type=> 0 then partial_wallet_payment
    company = Company.find_by_id(company_id)
    @payment_type = payment_type.to_s.eql?('1') ? 1 : 2
    @subscription = company.subscription
    attachments.inline['logo.jpg'] = File.read(Rails.root.join('app', 'assets/images/logo.jpg'))
    mail(to: company.account.email, subject: 'Wallet Payment Reminder')
  end

  def expire_trial_subscription(company)
    @company = company
    send_to_email = company.try(:account).try(:email) || company.email
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: send_to_email, subject: 'Trial Subscription Expired')
  end


  def payment_deduction(company_id,amount)
    @amount = amount
    company = Company.find_by_id(company_id)
    send_to_email = company.try(:account).try(:email) || company.email
    attachments.inline['logo.jpg'] = File.read(Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: send_to_email, subject: 'Payment Debited by Credit Card')
  end


end
