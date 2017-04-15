class CreditCardController < ApplicationController
  respond_to :json
  include CreditCardHelper
  before_filter :authorize
  # skip_before_action :verify_authenticity_token
  before_action :set_company
  before_action :set_sms_plan, :only => [:sms_credit]

  def add_vault
    credit_card = PaymentGateway::NMI::CreditCard.new(credit_card_params, @company)
    card_validation, errors = credit_card.validate
    if card_validation && !errors
      payment = PaymentGateway::NMI::DirectPayment.new(PaymentGateway::NMI::Address.new(@company), 0, @company, nil, credit_card)
      gateway_response = payment.initial_payment
      gateway_response = add_card_into_vault(@company, credit_card) if gateway_response['response'].eql?('1') && gateway_response['cvvresponse'].to_s.eql?('M')
      if gateway_response['response'].eql?('1') && gateway_response['customer_vault_id'].present?
        render :json => {:flag => true, :data => {:company_profile_id => @company.vault_id, :company_payment_profile_id => @company.vault_id}, :message => 'Credit card registered Successfully'} and return
      elsif gateway_response['response'].eql?('1') && gateway_response['cvvresponse'].to_s.eql?('N')
        render :json => {:flag => false, :data => {:company_profile_id => @company.vault_id, :company_payment_profile_id => @company.vault_id}, :message => 'Credit card cvv does not matched'} and return
      else
        render :json => {:flag => false, :message => gateway_response['responsetext']} and return
      end
    else
      render :json => {:flag => false,:error => errors, :is_credit_card_errors => true} and return
    end

  end

  def edit
    result = {}
  end

  def update_vault

    credit_card = PaymentGateway::NMI::CreditCard.new(credit_card_params, @company)
    card_validation, errors = credit_card.validate
    if card_validation && !errors
      payment = PaymentGateway::NMI::DirectPayment.new(PaymentGateway::NMI::Address.new(@company), 0, @company, nil, credit_card)
      # update company vault detail on NMI
      gateway_response = payment.initial_payment
      gateway_response = update_customer_vault(@company, credit_card) if gateway_response['response'].eql?('1') && gateway_response['cvvresponse'].to_s.eql?('M')

      if gateway_response['response'].eql?('1') && gateway_response['customer_vault_id'].present?
        render :json => {:flag => true, :data => {:company_profile_id => @company.vault_id, :company_payment_profile_id => @company.vault_id}, :message => 'Credit card updated Successfully'} and return
      elsif gateway_response['response'].eql?('1') && gateway_response['cvvresponse'].to_s.eql?('N')
        render :json => {:flag => false, :data => {:company_profile_id => @company.vault_id, :company_payment_profile_id => @company.vault_id}, :message => 'Credit card cvv does not matched'} and return
      else
        render :json => {:flag => false, :message => gateway_response['responsetext']} and return
      end
    else
      # return card validation error
      render :json => {:flag => false, :error => errors, :is_credit_card_errors => true}
    end

  end

  def card_status
    if @company.vault_id
      render :json => {:flag => true, :message => 'Your credit card is registered with us', :data => {:company_profile_id => @company.vault_id, :company_payment_profile_id => @company.vault_id}}
    else
      render :json => {:flag => false, :message => 'Credit card is not registered with us', :data => {:company_profile_id => @company.try(:vault_id), :company_payment_profile_id => @company.try(:vault_id)}}
    end
  end


  def sms_credit
    render :json => {:flag => false, :message => 'Credit card is not registered with us'} and return unless @company.vault_id
    gateway_response, sms_setting = sms_credit_payment(@company, @sms_plan)
    if gateway_response['response'].eql?('1')
      render :json => {:flag => true, :message => gateway_response['responsetext'], :data => {:sms_count => sms_setting.default_sms.to_s}}
    else
      render :json => {:flag => false, :message => gateway_response['responsetext']}
    end
  end


  private

  def set_company
    @company = Company.find_by_id(session[:comp_id])
  end

  def set_sms_plan
    @sms_plan = SmsPlan.find_by_id(params[:plan_id])
  end

  def credit_card_params
    params.permit(:card_number, :expiry_month, :expiry_year, :cvv)
  end


end
