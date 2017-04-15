module SubscriptionHelper

  def save_cancellation_feedback(company)
    subscription_cancellation = company.cancel_subscriptions.build(cancel_subscription_params)
    subscription_cancellation.save(:callback => false)
  end

  def payment_by_wallet_and_card(company, plan)
    plan_amount = plan.price
    wallet_amount = company.wallet
    next_billing_cycle = plan.category.to_s.eql?('Yearly') ? (Time.now+1.year).strftime('%Y%m%d').to_s : (Time.now+1.month).strftime('%Y%m%d').to_s
    return (company.wallet > plan_amount) ?
        process_subscription_type1(company, wallet_amount, plan_amount, plan, next_billing_cycle) :
        process_subscription_type2(company, wallet_amount, plan_amount, plan, next_billing_cycle)
  end

  def apply_L_to_H_plan(company, next_plan, current_plan, current_plan_use_days)
    payable_amount = lower_to_higher_plan_charges(next_plan, current_plan, current_plan_use_days)
    wallet_amount = @company.wallet
    next_billing_cycle = next_plan.category.to_s.eql?('Yearly') ? (Time.now+1.year).strftime('%Y%m%d').to_s : (Time.now+1.month).strftime('%Y%m%d').to_s
    return (@company.wallet > payable_amount) ?
        process_subscription_type5(company, wallet_amount, payable_amount, next_plan, next_billing_cycle) :
        process_subscription_type6(company, wallet_amount, payable_amount, next_plan, next_billing_cycle)
  end

  def apply_H_to_L_plan(company, next_plan, current_plan, current_plan_use_days)
    next_billing_cycle = next_plan.category.to_s.eql?('Yearly') ? (Time.now+1.year).strftime('%Y%m%d').to_s : (Time.now+1.month).strftime('%Y%m%d').to_s
    payable_amount, wallet_credit = higher_to_lower_plan_charges(next_plan, current_plan, current_plan_use_days)
    return ((payable_amount == 0) && (wallet_credit > 0)) ?
        process_subscription_type3(company, wallet_credit, next_plan, next_billing_cycle) :
        process_subscription_type4(company, wallet_credit, payable_amount, next_plan, next_billing_cycle)
  end

  # if company wallet balance is higher that pro-rata bases payable amount
  def process_subscription_type1(company, wallet_amount, payable_amount, next_plan, next_billing_cycle)
    # create a new subscription
    gateway_response = create_new_subscription(company, next_plan, next_billing_cycle)
    # deduct wallet balance
    company.update_columns(:wallet => wallet_amount - payable_amount) if gateway_response['response'].to_s.eql?('1')
    # gateway_response,used_wallet_amount,wallet_credit,payable_amount
    return gateway_response, {:used_wallet_amount => payable_amount, :wallet_credit => 0, :payable_amount => 0, :last_plan => company.subscription.cost}
  end

  # if company wallet balance is lower that pro-rata bases payable amount
  def process_subscription_type2(company, wallet_amount, payable_amount, next_plan, next_billing_cycle)
    # if payable amount equal to wallet amount
    gateway_response = if (payable_amount == wallet_amount) then
                         make_gateway_response(true)
                       else
                         # use wallet balance to make subscription
                         payable_amount = payable_amount - wallet_amount
                         credit_card_payment(company, payable_amount, next_plan)
                       end

    # create a new subscription
    gateway_response = create_new_subscription(company, next_plan, next_billing_cycle) if gateway_response['response'].eql?('1')
    # reset wallet balance to zero
    company.update_columns(:wallet => 0) if gateway_response['response'].eql?('1')
    # gateway_response,used_wallet_amount,wallet_credit,payable_amount
    return gateway_response, {:used_wallet_amount => wallet_amount, :wallet_credit => 0, :payable_amount => payable_amount, :last_plan => company.subscription.cost}
  end

  def process_subscription_type3(company, wallet_amount, next_plan, next_billing_cycle)
    gateway_response = company.subscription.nmi_subscription_id.present? ? cancel_and_renew_subscription(company, next_plan, next_billing_cycle) : create_new_subscription(company, next_plan, next_billing_cycle)
    # credit wallet balance
    company.update_columns(:wallet => company.wallet + wallet_amount) if gateway_response['response'].eql?('1')
    # gateway_response,used_wallet_amount,wallet_credit,payable_amount
    return gateway_response, {:used_wallet_amount => 0, :wallet_credit => wallet_amount, :payable_amount => 0, :last_plan => company.subscription.cost}
  end


  def process_subscription_type4(company, wallet_amount, payable_amount, next_plan, next_billing_cycle)

    # if payable amount equal to wallet amount
    gateway_response = if (payable_amount == wallet_amount) then
                         make_gateway_response(true)
                       else
                         # use wallet balance to make subscription
                         payable_amount = payable_amount - wallet_amount
                         credit_card_payment(company, payable_amount, next_plan)
                       end

    # cancel and create new subscription
    gateway_response = cancel_and_renew_subscription(company, next_plan, next_billing_cycle) if gateway_response['response'].eql?('1')
    # reset wallet balance to zero
    company.update_columns(:wallet => 0) if gateway_response['response'].eql?('1')
    # gateway_response,used_wallet_amount,wallet_credit,payable_amount
    return gateway_response, {:used_wallet_amount => wallet_amount, :wallet_credit => 0, :payable_amount => payable_amount, :last_plan => company.subscription.cost}
  end


  def process_subscription_type5(company, wallet_amount, payable_amount, next_plan, next_billing_cycle)
    gateway_response = cancel_and_renew_subscription(company, next_plan, next_billing_cycle)
    # deduct wallet balance
    company.update_columns(:wallet => wallet_amount - payable_amount) if gateway_response['response'].eql?('1')
    # gateway_response,used_wallet_amount,wallet_credit,payable_amount
    return gateway_response, {:used_wallet_amount => payable_amount, :wallet_credit => 0, :payable_amount => 0, :last_plan => company.subscription.cost}
  end

  def process_subscription_type6(company, wallet_amount, payable_amount, next_plan, next_billing_cycle)

    # if payable amount equal to wallet amount
    gateway_response = if (payable_amount == wallet_amount) then
                         make_gateway_response(true)
                       else
                         # use wallet balance to make subscription
                         payable_amount = payable_amount - wallet_amount
                         credit_card_payment(company, payable_amount, next_plan)
                       end

    # cancel and create new subscription
    gateway_response = cancel_and_renew_subscription(company, next_plan, next_billing_cycle) if gateway_response['response'].eql?('1')
    # reset wallet balance to zero
    company.update_columns(:wallet => 0) if gateway_response['response'].eql?('1')
    # gateway_response,used_wallet_amount,wallet_credit,payable_amount
    return gateway_response, {:used_wallet_amount => wallet_amount, :wallet_credit => 0, :payable_amount => payable_amount, :last_plan => company.subscription.cost}
  end


  def cancel_and_renew_subscription(company, next_plan, next_billing_cycle)
    # cancel current plan subscription
    recurring_billing = PaymentGateway::NMI::Subscription.new(company, next_plan, next_billing_cycle)
    gateway_response = recurring_billing.cancel
    # create new plan subscription
    gateway_response = recurring_billing.create if gateway_response['response'].eql?('1')
    return gateway_response
  end

  def credit_card_payment(company, payable_amount, next_plan)
    payment = PaymentGateway::NMI::DirectPayment.new(PaymentGateway::NMI::Address.new(company), payable_amount, company, next_plan)
    return payment.auth_and_capture
  end

  def update_subscription(company, subscription, plan, current_billing_cycle, next_billing_cycle, gateway_response, payment_info, next_plan_cost=nil, current_plan_cost=nil)
    subscription.update(name: plan.name, doctors_no: plan.no_doctors, purchase_date: Date.today, cost: plan.price, category: plan.category, :plan => plan, :payment_info => payment_info, :current_billing_cycle => current_billing_cycle, :next_billing_cycle => next_billing_cycle, :nmi_subscription_id => gateway_response['subscription_id'], :is_subscribed => true, :is_trial => false)
    if next_plan_cost.present? && current_plan_cost.present?
      (next_plan_cost > current_plan_cost) ? SubscriptionMailer.sidekiq_delay(:queue => 'subscription').low_to_high_plan_change(company.id) : SubscriptionMailer.sidekiq_delay(:queue => 'subscription').high_to_low_plan_change(company.id)
    else
      SubscriptionMailer.sidekiq_delay(:queue => 'subscription').new_subscription(company.id)
    end
  end

  def create_new_subscription_after_payment(company, plan, next_billing_cycle)
    # next_billing_cycle = Time.now+1.day
    # create new plan subscription
    recurring_billing = PaymentGateway::NMI::Subscription.new(company, plan, next_billing_cycle)
    # gateway_response = {}
    # gateway_response['response'] = '1'
    gateway_response = credit_card_payment(company, plan.price, plan)
    gateway_response = recurring_billing.create if gateway_response['response'].to_s.eql?('1')
    return gateway_response
  end


  def create_new_subscription(company, next_plan, next_billing_cycle)
    # create a new subscription
    recurring_billing = PaymentGateway::NMI::Subscription.new(company, next_plan, next_billing_cycle)
    return recurring_billing.create
  end

  def make_gateway_response(status)
    hash = {}
    return status ? hash.merge!(:response => '1', :responsetext => 'Success').stringify_keys! : hash.merge!(:response => '3', :responsetext => 'Error').stringify_keys!
  end


end
