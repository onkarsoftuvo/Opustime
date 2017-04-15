class QuickBookController < ApplicationController
  before_filter :authorize
  skip_before_action :verify_authenticity_token, :only => [:save_account_setting]
  before_filter :find_company_by_sub_domain
  before_action :set_qbo_objects
  before_filter :check_authorization


  def authenticate
    auth = QboAuthentication.find_or_create_by(:company => @company)
    begin
      base_url = "#{request.protocol}#{request.host_with_port}"
      session[:qbo_redirection_setting] = params[:code] if params[:code].present?
      callback = "#{base_url}/settings/quickbook/oauth_callback?company_id=#{@company.id}"
      # $qb_oauth_consumer is initialized in a initialize class - quick_book.rb
      # resolution of Marshal.dumb to convert auth object into byte stream
      token = $qb_oauth_consumer.get_request_token(:oauth_callback => callback)
      auth.token = token.token
      auth.secret = token.secret
      auth.save!
      # session[:qb_request_token] = Marshal.dump(token)
      redirect_to("https://appcenter.intuit.com/Connect/Begin?oauth_token=#{token.token}") and return
    rescue SocketError
      sleep 5
      retry
    end
  end

  # Quickbooks callback
  def oauth_callback
    # delete company QBO accounts
    @company.qbo_accounts.destroy_all
    # delete company QBO taxes
    @company.tax_settings.where(:qbo_tax => true).destroy_all
    pending_auth = QboAuthentication.find_by_company_id(params[:company_id])
    base_url = "#{request.protocol}#{request.host_with_port}"
    begin
      request_token = OAuth::RequestToken.new($qb_oauth_consumer, pending_auth.token, pending_auth.secret)
      # resolution of Marshal.load to convert byte stream into auth object
      at = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
      # at = Marshal.load(session[:qb_request_token]).get_access_token(:oauth_verifier => params[:oauth_verifier])
      token = at.token
      secret = at.secret
      realm_id = params['realmId']
      pending_auth.destroy
      # find qbo info object by realm_id and company_id
      qbo_info = QuickBookInfo.find_or_create_by(:company=>@company,:realm_id=>realm_id)
      qbo_info.assign_attributes(token: token, secret: secret, realm_id: realm_id, :token_expires_at => 6.months.from_now.utc, :reconnect_token_at => 5.months.from_now.utc)
      qbo_info.save!

      # qbo_info = QuickBookInfo.find_by_realm_id_and_company_id(realm_id, @company.id)

      # if qbo_info.blank?
      #   qbo_info = @company.build_quick_book_info(token: token, secret: secret, realm_id: realm_id, :token_expires_at => 6.months.from_now, :reconnect_token_at => 5.months.from_now)
      #   qbo_info.save
      # end

      # redirect_to quickbooks integration page
      if session[:qbo_redirection_setting].present? && session[:qbo_redirection_setting].to_s.eql?('tax')
        session[:qbo_redirection_setting] = nil
        redirect_to "#{base_url}#!/settings/taxes"
      else
        redirect_to "#{base_url}#!/settings/integration"
      end
    rescue SocketError
      sleep 5
      retry
    end

  end


  # return Quickbooks connection status and also list of accounts and tax
  def qbo_status

    if params[:code].to_s.eql?('tax')
      if @qbo_info.present?
        response = qbo_taxes(@qbo_info)
        render :json => {:flag => true, :id => @qbo_info.id, :is_connected => true, :message => 'Connect with Quickbooks', :data => response}
      else
        render :json => {:flag => true, :is_connected => false, :message => 'Disconnected with Quickbooks'}
      end

    else
      response = []
      if @qbo_info.present?
        # Fetch Quickbooks Income , Expense accounts and Tax rates
        if @company.qbo_accounts.size > 0
          response.push({'Expense' => @qbo_account.find_by_account_type_from_db('Expense', @company.id)}, {'Income' => @qbo_account.find_by_account_type_from_db('Income', @company.id)}, qbo_taxes(@qbo_info))
          response = merge_extra_fields(@qbo_info, response)
          @qbo_info.update(:expense_account_ref => response[0]['Expense'][0]['Id'], :income_account_ref => response[1]['Income'][0]['Id']) if @qbo_info.income_account_ref.blank? || @qbo_info.expense_account_ref.blank?
        else
          response = @qbo_account.find_income_and_expense_accounts_from_remote
          if response.present?
            response.each do |record|
              record['Expense'].each { |expense_record| @company.qbo_accounts.create(:account_name => expense_record['Name'], :account_type => expense_record['AccountType'], :account_ref => expense_record['Id']) } if record.has_key?('Expense')
              record['Income'].each { |income_record| @company.qbo_accounts.create(:account_name => income_record['Name'], :account_type => income_record['AccountType'], :account_ref => income_record['Id']) } if record.has_key?('Income')
            end
            response = merge_extra_fields(@qbo_info, response)
            @qbo_info.update(:expense_account_ref => response[0]['Expense'][0]['Id'], :income_account_ref => response[1]['Income'][0]['Id'])
          end
        end
        render :json => {:flag => true, :id => @qbo_info.id, :is_connected => true, :message => 'Connect with Quickbooks', :data => response}
      else
        render :json => {:flag => true, :is_connected => false, :message => 'Disconnected with Quickbooks'}
      end

    end

  end

  # return expense account list
  def expense_accounts_list
    response = []
    # qbo_info = find_qbo_info_object(session[:comp_id])
    if @qbo_info.present?
      # Fetch Quickbooks Expense accounts from db
      # qbo_account = Quickbooks::Account.new($token, $secret, $realm_id)
      response.push({'Expense' => @qbo_account.find_by_account_type_from_db('Expense', @company.id), 'selected_id' => @qbo_info.try(:expense_account_ref).to_s})
      render :json => {:flag => true, :id => @qbo_info.id, :is_connected => true, :message => 'Connect with Quickbooks', :data => response}
    else
      render :json => {:flag => true, :is_connected => false, :message => 'Disconnected with Quickbooks'}
    end
  end

  # save Quickbooks accounts and tax settings
  def save_account_setting
    begin
      if @qbo_info.present?
        @qbo_info.assign_attributes(qbo_setting_params)
        @qbo_info.save
        render :json => {:flag => true, :is_connected => true, :message => 'Setting saved successfully'}
      else
        render :json => {:flag => false, :is_connected => false, :message => 'Record not found'}
      end
    rescue Exception => error
      render :json => {:flag => false, :message => error.message}
    end

  end

  # disconnect from Quickbooks
  def disconnect_qbo
    if @qbo_info.try(:destroy)
      session[:realm_id] = nil
      # if qbo info record is destroy
      qbo_connection = Quickbooks::Connection.new($token, $secret, $realm_id)
      qbo_connection.disconnect(@company)
      render :json => {:flag => true, :is_connected => false, :message => 'Disconnected with Quickbooks'}
    else
      # if qbo info record is unable to  destroy
      render :json => {:flag => false, :is_connected => true, :message => 'Connect with Quickbooks'}
    end
  end

  def sync_qbo_taxes
    if @qbo_info.present?
      # reset all store quickbooks tax codes
      @qbo_info.company.tax_settings.where(:qbo_tax => true).destroy_all
      tax_array = qbo_tax_processing
      response = {'Tax' => tax_array.present? ? tax_array.sort_by { |record| record['Id'].to_i } : [], 'selected_id' => @qbo_info.try(:tax_code_ref).to_s}
      render :json => {:flag => true, :id => @qbo_info.id, :is_connected => true, :message => 'Connect with Quickbooks', :data => response}
    else
      render :json => {:flag => true, :is_connected => false, :message => 'Disconnected with Quickbooks'}
    end

  end

end

private

def check_authorization
  authorize! :manage , :integration
end

def set_qbo_objects
  @qbo_account = Quickbooks::Account.new($token, $secret, $realm_id)
  @qbo_info = QuickBookInfo.find_by_company_id(session[:comp_id])
end

def qbo_setting_params
  params.require(:quick_book).permit(:income_account_ref, :expense_account_ref, :tax_code_ref, :company_id)
end

# merge additional fields into response
def merge_extra_fields(qbo_info, response)
  # qbo_info.update(:expense_account_ref => response[0]['Expense'][0]['Id'], :income_account_ref => response[1]['Income'][0]['Id'], :tax_code_ref => nil) if qbo_info.income_account_ref.blank? && qbo_info.expense_account_ref.blank?
  response[0].merge!('selected_id' => qbo_info.try(:expense_account_ref).to_s)
  response[1].merge!('selected_id' => qbo_info.try(:income_account_ref).to_s)
  response[2] = qbo_taxes(qbo_info)
  response[2].merge!('selected_id' => qbo_info.try(:tax_code_ref).to_s) if response[2].present?
  response
end

def qbo_tax_processing
  qbo_tax = Quickbooks::Tax.new($token, $secret, $realm_id)
  tax_response = qbo_tax.save_company_taxes(@qbo_info)
  tax_response.sort_by { |record| record['Id'].to_i }.each_with_index { |record, index| tax_response[index] = record.select { |k, v| ['Id', 'name', 'amount'].include?(k) } } if tax_response.present?
  tax_response
end

# merge additional tax filed into response
def qbo_taxes(qbo_info)
  tax_array = []
  # execute if block, if local db (qbo_taxes) is updated
  company_all_taxes = qbo_info.company.tax_settings.where(:qbo_tax => true)
  if company_all_taxes.first.present?
    company_all_taxes.all.each do |record|
      record = record.as_json.select { |k, v| ['name', 'amount', 'tax_code_ref'].include?(k) }
      record.clone.each do |key, val|
        record['Id'] = val if key.to_s.eql?('tax_code_ref')
      end
      # tax_rates = []
      # record.qbo_tax_rates.each { |tax_rate| tax_rates.push(tax_rate.as_json.select { |k, v| ['amount'].include?(k) }) }
      tax_array.push(record.select { |k, v| ['name', 'amount', 'Id'].include?(k) })
    end
  else
    # execute else block if local db is not updated
    tax_array = qbo_tax_processing
  end
  response = {'Tax' => tax_array.present? ? tax_array.sort_by { |record| record['Id'].to_i } : [], 'selected_id' => qbo_info.try(:tax_code_ref).to_s}
  response
end


