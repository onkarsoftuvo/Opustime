class XeroSessionsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_filter :get_xero_gateway
  before_filter :find_company_by_sub_domain , :only => [:recieve_xero_token, :is_xero_connected , :disconnect , :save_xero_settings]
    
  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def new
    base_url = "#{request.protocol}#{request.host_with_port}"
    request_token = @xero_gateway.request_token(:oauth_callback => "#{base_url}/#!/settings/integration")
    session[:request_token]  = request_token.token
    session[:request_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end
  
  def recieve_xero_token
    begin 
      oauth_verifier = params[:oauth_verifier]
      @xero_gateway.authorize_from_request(session[:request_token] , session[:request_secret], :oauth_verifier => oauth_verifier)
      session.delete(:request_token) 
      session.delete(:request_secret)
      
      access_token = @xero_gateway.access_token.token
      access_secret = @xero_gateway.access_token.secret
      xero_model = @company.create_xero_session(is_connected: true, access_token: access_token , access_secret: access_secret )

      # Default Xero sales account for invoice items
      result = {}      
      result[:account_invoice_items_list] = get_account_lists(@xero_gateway)
      result[:account_payments_list] = get_payment_types_list(@xero_gateway)
      result[:account_tax_rates_list] = get_xero_taxt_types(@xero_gateway)
      result[:is_connected] = true
      render :json => result
    rescue Exception => e
      result = {}
      result[:error] = e.message
      result[:is_connected] = false 
      render :json => result
    end
  end 
  
  
  def disconnect 
    @company.xero_session = nil 
    render :json => { :is_connected=> false }
  end      
  
  def is_xero_connected
    begin
      xero_model = @company.xero_session
      unless xero_model.nil?
        result = {}
        result[:account_invoice_items_list] = get_account_lists(@xero_gateway)
        
        result[:selected_account_invoice_item] = xero_model.inv_item_code
        
        result[:account_payments_list] = get_payment_types_list(@xero_gateway)
        
        result[:selected_account_payment] = xero_model.payment_code
        
        result[:account_tax_rates_list] = get_xero_taxt_types(@xero_gateway)
        
        result[:seleced_account_tax_rate] = xero_model.tax_rate_code
        
        result[:is_connected] = true
        render :json => result 
      else
        render :json => { :is_connected=> false }  
      end
    rescue Exception => e
      result = {}
      result[:error] = e.message
      result[:is_connected] = false
      render :json => result
    end
  end
  
  def save_xero_settings
    xero_model = @company.xero_session
    inv_code = params[:inv_item_code]
    payment_code = params[:payment_code]
    tax_rate_code = params[:tax_rate_code]
     
    xero_model.update_attributes(inv_item_code: inv_code , payment_code: payment_code , tax_rate_code: tax_rate_code)
    render :json=> {flag: xero_model.valid?} 
  end
  
end
