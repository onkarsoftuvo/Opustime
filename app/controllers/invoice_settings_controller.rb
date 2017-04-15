class InvoiceSettingsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain, :only => [:edit]
  before_action :find_invoice_setting, only: [:update]

  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  load_and_authorize_resource param_method: :invoice_setting_params
  before_filter :load_permissions

  # def index
  # invoices = InvoiceSetting.where(["status= ? AND company_id= ?", true , @company.id]).specific_attributes
  # render :json => invoices
  # end
  #
  # def new
  # invoice = InvoiceSetting.new
  # result = {}
  # result[:invoice_setting] = invoice
  # render :json =>  result
  # end
  #
  # def create
  # invoice = @company.build_invoice_setting(invoice_setting_params)
  # if invoice.valid?
  # invoice.save
  # result = { flag: true, id: invoice.id}
  # render :json=>  result
  # else
  # show_error_json(invoice.errors.messages)
  # end
  # end

  def edit
    invoice_setting_id = @company.invoice_setting.id
    invoice_setting = InvoiceSetting.where(id: invoice_setting_id).specific_attributes.first
    result = {}
    result[:invoice_setting] = invoice_setting
    render :json => result
  end

  def update
    invoice = @invoice.first
    if invoice.starting_invoice_number.blank?
      invoice.assign_attributes(invoice_setting_params)
      invoice.assign_attributes(:next_invoice_number => invoice.starting_invoice_number)
    elsif invoice.starting_invoice_number.present? && (params[:invoice_setting][:starting_invoice_number].to_i > invoice.starting_invoice_number)
      invoice.assign_attributes(invoice_setting_params)
      invoice.assign_attributes(:next_invoice_number=>params[:invoice_setting][:starting_invoice_number].to_i)
    else
      invoice.assign_attributes(invoice_setting_params)
    end

    if invoice.save
      result = {flag: true}
      render json: result
    else
      show_error_json(invoice.errors.messages)
    end
  end

  # def destroy 
  # invoice = @invoice.first
  # invoice.update(status: false)
  # if invoice.valid?
  # result = {flag: true }
  # render json: result
  # else
  # show_error_json(invoice.errors.messages)
  # end
  # end

  private

  def find_invoice_setting
    @invoice = InvoiceSetting.where(id: params[:id])
  end

  def invoice_setting_params
    params.require(:invoice_setting).permit(:id, :title, :starting_invoice_number, :next_invoice_number, :extra_bussiness_information, :offer_text, :default_notes, :show_business_info, :hide_business_details, :include_next_appointment)
  end
end
