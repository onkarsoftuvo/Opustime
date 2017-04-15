class SubscriptionController < ApplicationController
  respond_to :json
  include Opustime::Utility
  include SubscriptionHelper
  before_filter :authorize
  before_action :find_company_by_sub_domain
  before_action :set_subscription_plan, :only => [:update]
  before_action :set_subscription

  before_filter :check_authorization


  def index
    plans = Owner.find_by_role("super_admin_user").plans.active_plan.order('price asc').select("id , name , no_doctors , price , category")
    result = {}
    current_plans = []
    no_practitioners =@company.users.doctors.count
    remaining_days = total_days(@subscription.end_date, Date.today)

#   To add subscription details
    subscription_details = {current_plan: @subscription.name,
                            avail_practi: no_practitioners,
                            max_practi: @subscription.doctors_no,
                            next_billing_date: @subscription.try(:next_billing_cycle).try(:strftime, '%A, %d %b %Y'),
                            category: @subscription.category,
                            fee: @subscription.cost,
                            remaining_days: remaining_days,
                            email_id: @company.email,
                            trail: @subscription.is_trial}

# subscription_details = subscription.is_subscribed ? subscription_details : {}

#   To show list all
    plans.each do |plan|
      if plan.name == @subscription.try(:name) && plan.category == @subscription.try(:category) && (@subscription.is_subscribed || @subscription.is_trial)
        item = {id: @subscription.id, name: @subscription.name, no_doctors: @subscription.doctors_no, price: @subscription.cost, category: @subscription.category, is_selected: true}
      else
        if no_practitioners > plan.no_doctors
          item = {id: plan.id, name: plan.name, no_doctors: plan.no_doctors, price: plan.price, category: plan.category, is_selected: false, not_available: true}
        else
          item = {id: plan.id, name: plan.name, no_doctors: plan.no_doctors, price: plan.price, category: plan.category, is_selected: false}
        end
      end
      current_plans << item
    end
    result[:subscription_detail] = subscription_details
    result[:plans] = current_plans
    result[:is_trial] = @subscription.is_trial
    result[:is_subscribed] = @subscription.is_subscribed
    result[:show_cancel_subscription_button] = @subscription.is_subscribed ? true : false
    result[:is_trial_expired] = !@subscription.is_trial
    result[:active_subscription] = @subscription.is_subscribed ? true : false
    result[:trial_subscription_message] = "Your subscription is currently Trialing (#{remaining_days} #{'day'.pluralize(remaining_days.to_i)} remaining)"
    render :json => result
  end


  # # create new subscription by company
  # # subscription payment made by Authorize.net
  def update
    render :json => {:flag => false, :message => 'Credit card is not registered with us'} and return unless @company.vault_id
    next_billing_cycle = @subscription_plan.category.to_s.eql?('Yearly') ? Time.now+1.year : Time.now+1.month
    current_billing_cycle = Time.now
    # current_billing_cycle = @subscription.next_billing_cycle.present? && (Date.today > @subscription.next_billing_cycle.to_date) ? @subscription.next_billing_cycle : Time.now
    response, response_message = @subscription.nmi_subscription_id.present? ? renew_subscription(@subscription, @subscription_plan, current_billing_cycle, next_billing_cycle) : initialize_new_subscription(@subscription, @subscription_plan, current_billing_cycle, next_billing_cycle)
    render :json => {flag: response.to_s.eql?('1') ? true : false, :message => response_message} and return
  end


  def cancel
    render :json => {:flag => false, :message => 'You have no active subscription'} and return unless @subscription.nmi_subscription_id.present?
    recurring_billing = PaymentGateway::NMI::Subscription.new(@company)
    gateway_response = recurring_billing.cancel
    if gateway_response['response'].eql?('1')
      @subscription.update(:is_subscribed => false, :is_trial => false, :nmi_subscription_id => nil, :current_billing_cycle => nil, :next_billing_cycle => nil)
      save_cancellation_feedback(@company)
      SubscriptionMailer.sidekiq_delay(:queue => 'subscription').cancel_subscription(@company.id)
    end
    render :json => {flag: gateway_response['response'].to_s.eql?('1') ? true : false, :message => gateway_response['responsetext']} and return
  end


  def wallet_balance
    render :json => {:balance => @company.wallet.round(2)}
  end

  def permission
    render :json => [{:is_trial => @company.subscription.is_trial, :is_subscribed => @company.subscription.is_subscribed}]
  end

  private

  def check_authorization
    authorize! :manage, Subscription
  end

  def set_subscription_plan
    @subscription_plan = Plan.find(params[:id])
  end

  def set_subscription
    @subscription = @company.subscription
  end

  def set_company
    @company = Company.find_by_id(session[:comp_id])
  end

  def cancel_subscription_params
    params.permit(:reason, :description)
  end


  # This method first cancel previous subscription and create a new subscription
  def renew_subscription(subscription, plan, current_billing_cycle, next_billing_cycle)
    current_plan_cost = subscription.cost
    next_plan_cost = plan.price
    current_plan_use_days = total_days(Time.now.to_date, subscription.current_billing_cycle)
    gateway_response, payment_info = (next_plan_cost > current_plan_cost) ? apply_L_to_H_plan(@company, plan, subscription, current_plan_use_days) : apply_H_to_L_plan(@company, plan, subscription, current_plan_use_days)
    update_subscription(@company, subscription, plan, current_billing_cycle, next_billing_cycle, gateway_response, payment_info, next_plan_cost, current_plan_cost) if gateway_response['response'].eql?('1')
    return gateway_response['response'], gateway_response['responsetext']
  end

  # This method create a new subscription
  def initialize_new_subscription(subscription, plan, current_billing_cycle, next_billing_cycle)
    gateway_response, payment_info = @company.wallet > 0 ? payment_by_wallet_and_card(@company, plan) : create_new_subscription_after_payment(@company, plan, next_billing_cycle)
    update_subscription(@company, subscription, plan, current_billing_cycle, next_billing_cycle, gateway_response, payment_info) if gateway_response['response'].eql?('1')
    return gateway_response['response'], gateway_response['responsetext']
  end


end
