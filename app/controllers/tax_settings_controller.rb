class TaxSettingsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain, :only => [:index, :create ]

  before_action :find_tax_setting, :only => [:edit, :update]

  # before_action :get_xero_gateway, :only => [:xero_info_for_tax]
  load_and_authorize_resource  param_method: :tax_setting_params , except: [:index]
  before_filter :load_permissions

  def index
    # if $qbo_credentials.present?
    #   taxes = @company.tax_settings.select("id , name , amount").where(:qbo_tax => true)
    # else
    # end
    taxes = @company.tax_settings.select("id , name , amount,tax_code_ref").where(:qbo_tax => false)
    render :json => taxes
  end

  def create
    tax = @company.tax_settings.new(tax_setting_params)
    if tax.valid?
      tax.save
      result = {flag: true, id: tax.id}
      render :json => result
    else
      show_error_json(tax.errors.messages)
    end
  end

  def edit
    result = {}

    result.merge!(:id => @tax_setting.try(:id), :name => @tax_setting.try(:name), :amount => @tax_setting.try(:amount),:tax_code_ref=>@tax_setting.try(:tax_code_ref))


    # if $qbo_credentials.present?
    #   tax_rates = []
    #   @tax_setting.qbo_tax_rates.each_with_index { |record, index| tax_rates[index] = record.as_json.select { |k, v| ['amount'].include?(k) } }
    #   result.merge!(:id => @tax_setting.try(:id), :name => @tax_setting.try(:name), :tax_rates => tax_rates)
    # else
    #   result.merge!(:id => @tax_setting.try(:id), :name => @tax_setting.try(:name), :amount => @tax_setting.try(:amount))
    # end
    render :json => result
  end

  def update
    @tax_setting.update_attributes(tax_setting_params)
    if @tax_setting.valid?
      result = {flag: true, id: @tax_setting.id}
      render :json => result
    else
      show_error_json(@tax_setting.errors.messages)
    end
  end

  def destroy
    # tax = TaxSetting.find(params[:id]) rescue nil
    # tax.destroy
    # render :json=>{flag: true}
  end

  # def xero_info_for_tax
  #   xero_model = @company.xero_session
  #   result = {flag: false}
  #   unless xero_model.nil?
  #     if xero_model.is_connected
  #       result = {}
  #       result[:is_connected] = xero_model.is_connected
  #       result[:account_tax_rates_list] = get_xero_taxt_types(@xero_gateway)
  #     end
  #   end
  #   render :json => result
  # end

  private

  def find_tax_setting
    # if $qbo_credentials.present?
    #   @tax_setting = TaxSetting.select("id, name , amount").find_by_id_and_qbo_tax(params[:id], true)
    # else
    # end

    @tax_setting = TaxSetting.select("id, name , amount,tax_code_ref").find_by_id_and_qbo_tax(params[:id], false)

  end

  def tax_setting_params
    params.require(:tax_setting).permit(:id, :name, :amount ,:tax_code_ref)
  end


end
