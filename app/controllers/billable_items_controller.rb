class BillableItemsController < ApplicationController
  include BillableItemsHelper

  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain, :only => [:index, :new, :create, :edit, :billable_item_list]
  before_action :find_billable_item, :only => [:edit, :update, :destroy]
  before_action :format_params_in_format, :only => [:create, :update]

  # before_action :get_xero_gateway, :only => [:xero_info_for_billable_items]

  load_and_authorize_resource  param_method: :billable_item_params , except: [:billable_item_list]
  before_filter :load_permissions

  def index
    billable_items = @company.billable_items.select("billable_items.id, billable_items.item_code , billable_items.name, billable_items.price , billable_items.include_tax , billable_items.tax , billable_items.item_type")
    result = []
    billable_items.each do |b_item|
      item = {}
      item[:id] = b_item.id
      item[:name] = b_item.name
      item[:item_code] = b_item.item_code
      item[:item_type] = b_item.item_type
      get_price_detail(b_item.price, b_item.tax, b_item.include_tax, item)
      # item[:price] = b_item.price  || get_price_detail(b_item.price ,b_item.tax , b_item.include_tax)
      #item[:tax] =   b_item.tax.to_s.casecmp("N/A") == 0 ? (b_item.tax) : (get_tax_detail(b_item.tax))
      item[:tax] = b_item.tax_setting.try(:id)
      item[:include_tax] = b_item.include_tax
      result << item
    end
    render :json => result
  end

  def new
    billable_item = @company.billable_items.new
    result ={}
    result[:id] = billable_item.id
    result[:item_code] = billable_item.item_code
    result[:name] = billable_item.name
    result[:price] = billable_item.price if billable_item.price.nil?
    get_price_detail(billable_item.price, billable_item.tax, billable_item.include_tax, result) unless billable_item.price.nil?
    result[:include_tax] = false
    result[:tax] = billable_item.tax_setting.try(:id)
    result[:item_type] = billable_item.item_type
    concessions = @company.concessions.select("id , name")
    result[:concession_price] = []
    concessions.each do |cs|
      item = {}
      item[:concession_id] = cs.id
      item[:name] = cs.name
      item[:value] = ""
      result[:concession_price] << item
    end
    render :json => result
  end

  def create
    billable_item = @company.billable_items.build(billable_item_params)
    if billable_item.valid?
      billable_item.save
      render :json => {flag: true, :id => billable_item.id}
    else
      show_error_json(billable_item.errors.messages)
    end
  end

  def edit
    result ={}
    result[:id] = @billable_item.id
    result[:item_code] = @billable_item.item_code
    result[:name] = @billable_item.name
    result[:income_account_ref] = @billable_item.income_account_ref.to_s
    result[:expense_account_ref] = @billable_item.expense_account_ref.to_s
    result[:price] = @billable_item.price if @billable_item.price.nil?
    get_price_detail(@billable_item.price, @billable_item.tax, @billable_item.include_tax, result) unless @billable_item.price.nil?
    result[:include_tax] = @billable_item.include_tax
    result[:tax] =  @billable_item.tax_setting.try(:id).to_s
    # result[:tax] = {}
    
    # bill_tax = BillableItemsTaxSetting.where(["billable_item_id = ? ", @billable_item.id])
    # item = {}
    # item[:id] = bill_tax.first.try(:id) unless bill_tax.first.try(:id).nil?
    # item[:tax_setting_id] = bill_tax.first.try(:tax_setting).try(:id).to_s
    # result[:tax] = item

    result[:item_type] = @billable_item.item_type
    # result[:xero_code] = @billable_item.xero_code
    result[:concession_price] = []
    bill_cs = BillableItemsConcession.where(["billable_item_id = ? ", @billable_item.id])
    used_concessions = []
    bill_cs.each do |bl_cs|
      item = {}
      item[:id] = bl_cs.id
      item[:concession_id] = bl_cs.concession.try(:id)
      used_concessions << bl_cs.concession.try(:id)
      item[:name] = bl_cs.concession.try(:name)
      item[:value] = (bl_cs.value.nil? || bl_cs.value.blank?) ? nil : bl_cs.value
      result[:concession_price] << item
    end

    #   new concessions which is not added
    if used_concessions.count > 0
      new_concessions = @company.concessions.where(["id NOT IN (?)", used_concessions]).select("id,name")
    else
      new_concessions = @company.concessions.select("id,name")
    end
    new_concessions.each do |cs|
      item = {}
      item[:concession_id] = cs.try(:id)
      item[:name] = cs.try(:name)
      item[:value] = nil
      result[:concession_price] << item
    end

    render :json => result

    # render :json => get_billable_item(@billable_item)
  end

  def update
    @billable_item.update_attributes(billable_item_params)
    if @billable_item.valid?
      result = {flag: true}
      render :json => result
    else
      show_error_json(@billable_item.errors.messages)
    end

  end

  def destroy
    @billable_item.destroy
    # QboItemDeleteWorker.perform_in(2.seconds,@billable_item.id, @billable_item.class, $token, $secret, $realm_id)
    result = {flag: true}
    render :json => result
  end

  def billable_item_list
    billable_items = @company.billable_items.select("billable_items.id , billable_items.name")
    render :json => billable_items
  end

  # def xero_info_for_billable_items
  #   xero_model = @company.xero_session
  #   result = {flag: false}
  #   unless xero_model.nil?
  #     if xero_model.is_connected
  #       result = {}
  #       result[:is_connected] = xero_model.is_connected
  #       result[:account_invoice_items_list] = get_account_lists(@xero_gateway)
  #     end
  #   end
  #   render :json => result
  # end

  private

  def billable_item_params
    params.require(:billable_item).permit(:id, :item_code, :name, :price, :include_tax, :tax, :item_type, :income_account_ref, :expense_account_ref, :billable_items_concessions_attributes => [:id, :concession_id, :value], :billable_items_tax_setting_attributes => [:id, :tax_setting_id, :_destroy])
  end

  def find_billable_item
    @billable_item = BillableItem.select("id, item_code , name , price , include_tax , tax , item_type , concession_price,income_account_ref,expense_account_ref").find(params[:id])
  end

  def get_tax_detail(id)
    begin
      tax = TaxSetting.find(id)
      return tax.name+" (#{tax.amount.to_f}%)"
    rescue Exception => e
      return nil
    end

  end

  def format_params_in_format
    params[:billable_item][:billable_items_concessions_attributes] = []
    params[:concession_price].each do |cs|
      item = {}
      item[:id] = cs[:id] unless cs[:id].nil?
      item[:concession_id] = cs[:concession_id]
      item[:value] = cs[:value]
      params[:billable_item][:billable_items_concessions_attributes] << item
    end unless params[:concession_price].nil?

    #Edited by manoranjan

    params[:billable_item][:billable_items_tax_setting_attributes] = {}
    item = {}
    tax_id = params[:billable_item][:tax].to_i
    if tax_id > 0
      if params[:action] =="update"

        unless tax_id == @billable_item.tax.to_i
          item[:tax_setting_id] = tax_id
          params[:billable_item][:billable_items_tax_setting_attributes] = item
        else
          record = BillableItemsTaxSetting.where(["billable_item_id =? AND tax_setting_id=? ", @billable_item.id, tax_id])
          item[:id] = record.first.try(:id)
          item[:tax_setting_id] = tax_id
          params[:billable_item][:billable_items_tax_setting_attributes] = item
        end
      else
        item[:tax_setting_id] = tax_id
        params[:billable_item][:billable_items_tax_setting_attributes] = item
      end
    else

      if params[:action] == "update"
        unless @billable_item.tax.nil?
          record = BillableItemsTaxSetting.where(["billable_item_id =? AND tax_setting_id=? ", @billable_item.id, @billable_item.tax]).first

          item[:id] = record.try(:id)
          item[:_destroy] = true
          params[:billable_item][:billable_items_tax_setting_attributes] = item
        end

      end
    end
    return params
  end

end
