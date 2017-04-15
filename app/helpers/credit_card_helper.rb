module CreditCardHelper

  def sms_credit_payment(company, sms_plan)
    # Check wallet balance to make payment
    sms_plan_amount = sms_plan.amount
    wallet_amount = company.wallet
    if wallet_amount > sms_plan_amount
      available_wallet_balance = wallet_amount - sms_plan_amount
      sms_setting = SmsSetting.find_by_company_id(company)
      # update wallet balance
      status = company.update_columns(:wallet => available_wallet_balance)
      gateway_response = make_gateway_response(status)
      # Update sms credit
      sms_setting.update_columns(:default_sms => sms_setting.default_sms.to_i+sms_plan.no_sms.to_i) if gateway_response['response'].eql?('1')
    else
      payable_amount = sms_plan_amount - wallet_amount
      payment = PaymentGateway::NMI::DirectPayment.new(PaymentGateway::NMI::Address.new(company), payable_amount, company, sms_plan)
      gateway_response = payment.auth_and_capture
      if gateway_response['response'].eql?('1') && gateway_response['transactionid'].present?
        # Reset wallet balance
        company.update_columns(:wallet => 0)
        sms_setting = SmsSetting.find_by_company_id(company)
        sms_setting.update_columns(:default_sms => sms_setting.default_sms.to_i+sms_plan.no_sms.to_i)
      end
    end

    return gateway_response, sms_setting
  end

  def add_card_into_vault(company, credit_card)
    customer_vault = PaymentGateway::NMI::CustomerVault.new(PaymentGateway::NMI::Address.new(company))
    gateway_response = customer_vault.create(company, credit_card, 'customer_vault=add_customer')
    company.update_column('vault_id', gateway_response['customer_vault_id']) if gateway_response['response'].to_s.eql?('1')
    # generate customer vault log
    PaymentGateway::NMI::TransactionLog.new(gateway_response, company).customer_vault_log
    return gateway_response

  end

  def update_customer_vault(company, credit_card)
    customer_vault = PaymentGateway::NMI::CustomerVault.new(PaymentGateway::NMI::Address.new(company))
    gateway_response = customer_vault.update(company, credit_card, 'customer_vault=update_customer')
    company.update_column('vault_id', gateway_response['customer_vault_id']) if gateway_response['response'].to_s.eql?('1')
    # generate customer vault log
    PaymentGateway::NMI::TransactionLog.new(gateway_response, company).customer_vault_log
    return gateway_response
  end

  def make_gateway_response(status)
    hash = {}
    return status ? hash.merge!(:response => '1', :responsetext => 'Success',:cvvresponse=>'M').stringify_keys! : hash.merge!(:response => '3', :responsetext => 'Error',:cvvresponse=>'N').stringify_keys!
  end


end
