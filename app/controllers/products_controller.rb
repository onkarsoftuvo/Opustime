class ProductsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain
  before_action :find_product, :only => [:update, :destroy, :edit]
  # before_action :prevent_access_from_unauth
  # before_action :stop_delete_unauth, :only => [:destroy]
  before_action :set_params_in_format, :only => [:create, :update]

  # before_action :get_xero_gateway, :only => [:xero_info, :index]

  load_and_authorize_resource  param_method: :params_product
  before_filter :load_permissions

  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    begin
      per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : Product.per_page
      unless params[:q].blank? || params[:q].nil?
        q = params[:q]
        arr = q.split(" ")
        products = @company.products.order("created_at desc").select("id ,item_code , name , serial_no ,  price_inc_tax , price_exc_tax , tax , cost_price , stock_number , note , price , supplier").active_products.where(["products.name LIKE ? OR products.name LIKE ? OR products.supplier LIKE ? OR products.price LIKE  ? ", "%#{arr.first}%", "%#{arr.last}%", "%#{params[:q]}%", "%#{params[:q]}%"]).paginate(:page => params[:page] , per_page: per_page)
      else
        products = @company.products.order("created_at desc").select('id ,item_code , name ,
         serial_no ,  price_inc_tax , price_exc_tax , tax , cost_price , stock_number ,
         note , price , supplier').active_products.paginate(:page => params[:page] , per_page: per_page)
      end

      # xero_data = get_account_lists(@xero_gateway) rescue nil
      result = []
      products.each do |product|
        item = {}
        item[:id] = product.id
        item[:item_code] = product.item_code
        item[:name] = product.name
        item[:price_inc_tax] = '% .2f'% (product.price_inc_tax.nil? ? 0 : product.price_inc_tax.round(2)).to_f
        item[:price_exc_tax] = '% .2f'% (product.price_exc_tax.nil? ? 0 : product.price_exc_tax.round(2)).to_f
        item[:tax] = product.tax_setting.try(:id)
        item[:cost_price] = '% .2f'% product.cost_price.to_f
        item[:stock_number] = product.stock_number
        item[:note] = product.note
        item[:price] = '% .2f'% product.price.to_f
        item[:supplier] = product.supplier
        result << item
      end

      render :json => {:product => result, total: products.count}

    rescue Exception => e
      render :json => {:error => e.message, :is_connected => false}
    end

  end

  def create
    if params[:product][:stock_number].to_i > 0
      product = @company.products.new(params_product)
      if product.valid?
        product.with_lock do
          # Babar Modification
          #-----------------------------------------------------------------
          product.product_stocks.build(stock_level: true,stock_type: "Initial Stock Level",quantity: product.stock_number, adjusted_at: DateTime.now.strftime('%e %b ,%Y,%l:%M%p') , adjusted_by: current_user.try(:id) )
          #------------------------------------------------------------------
          product.save
        end

        #----------------commented by Babar------------------
        # # product.set_status
        # product.create_stock(current_user.id)
        #----------------commented by Babar------------------
        result = {flag: true, id: product.id}
        render :json => result
      else
        show_error_json(product.errors.messages)
      end
    else
      product = Product.new
      product.errors.add(:stock_number, "must be greater than or equal to 1")
      show_error_json(product.errors.messages)
    end
  end

  def edit
    item = {}
    unless @product.nil?
      item[:id] = @product.id
      item[:item_code] = @product.item_code
      item[:name] = @product.name
      item[:serial_no] = @product.serial_no
      item[:price_inc_tax] = '% .2f'% @product.price_inc_tax.to_f
      item[:price_exc_tax] = '% .2f'% @product.price_exc_tax.to_f
      item[:tax] = @product.tax
      item[:cost_price] = '% .2f'% (@product.cost_price.to_f)
      item[:stock_number] = @product.stock_number
      item[:note] = @product.note
      item[:price] = '% .2f'% @product.price.to_f
      item[:supplier] = @product.supplier
      item[:next_product] =  @product.next_product
      item[:previous_product] = @product.prev_product
      item[:income_account_ref] = @product.income_account_ref.to_s
      item[:expense_account_ref] = @product.expense_account_ref.to_s
    end

    render :json => item

  end

  def update
    #---------- commented by Babar -----------------
    # @product.with_lock do
    #   status = @product.update(params_product)
    # end
    #---------- commented by Babar -----------------

    #------------------ Added by Babar-----------------------
    @product.assign_attributes(params_product)
    # @product.product_stocks.build(quantity: @product.stock_number, adjusted_at: Date.today , adjusted_by: current_user.try(:id) )
    #------------------ Added by Babar-----------------------


  if @product.valid?
    @product.save
    #---------- commented by Babar -----------------
    # @product.create_stock(current_user.id) if @product.product_stocks.count == 0
    #---------- commented by Babar -----------------
    result = {flag: true}
      render :json => result
    else
      show_error_json(@product.errors.messages)
    end

  end

  def destroy

    if @product.update_columns(:status => false)
      # product = Intuit::OpustimeDeleteItem.new(@product.id, @product.class, $token, $secret, $realm_id) if $qbo_credentials.present?
      # product.sync_delete
      result ={flag: true}
      render :json => result
    else
      show_error_json(@product.errors.messages)
    end

  end

  # def xero_info
  #   begin
  #     unless @xero_gateway.nil?
  #       xero_model = @company.xero_session
  #       result = {flag: false}
  #       unless xero_model.nil?
  #         if xero_model.is_connected
  #           result = {}
  #           result[:is_connected] = xero_model.is_connected
  #           acc_list = get_account_lists(@xero_gateway) rescue []
  #           result[:account_invoice_items_list] = acc_list
  #           result[:is_connected] = false if acc_list.length <= 0
  #         end
  #       end
  #       render :json => result
  #     else
  #       result = {flag: false}
  #       render :json => result
  #     end
  #   rescue
  #     render :json => {:error => e.message, :is_connected => false}
  #   end
  # end

  def check_security_role
    result = {}
    result[:view] = can? :index , Product
    result[:create] = can? :create , Product
    result[:modify] = can? :update , Product
    result[:delete] = can? :destroy , Product
    result[:stock] = can? :create , ProductStock
    render :json => result
  end

  private

  def params_product
    params.require(:product).permit(:id, :item_code, :name, :serial_no, :price, :include_tax, :tax, :cost_price, :stock_number, :note, :status, :supplier, :income_account_ref, :expense_account_ref,
                                    {:tax_settings_product_attributes => [:id, :tax_setting_id, :_destroy]})
  end

  #Edited by Manoranjan
  def set_params_in_format
    #managing tax_settings_product

    params[:product][:tax_settings_product_attributes] = {}
    item = {}
    tax_id = params[:product][:tax].to_i
    if tax_id > 0
      if params[:action] =="update"

        unless tax_id == @product.tax.to_i
          item[:tax_setting_id] = tax_id
          params[:product][:tax_settings_product_attributes] = item
        else
          record = TaxSettingsProduct.where(["product_id =? AND tax_setting_id=? ", @product.id, tax_id])
          item[:id] = record.first.try(:id)
          item[:tax_setting_id] = tax_id
          params[:product][:tax_settings_product_attributes] = item
        end
      else
        item[:tax_setting_id] = tax_id
        params[:product][:tax_settings_product_attributes] = item
      end
    else

      if params[:action] == "update"
        unless @product.tax.nil?
          record = TaxSettingsProduct.where(["product_id =? AND tax_setting_id=? ", @product.id, @product.tax]).first

          item[:id] = record.try(:id)
          item[:_destroy] = true
          params[:product][:tax_settings_product_attributes] = item
        end

      end
    end
    return params
  end

  def find_product
    @product = @company.products.find_by_id(params[:id])
  end

  # Filter to prevent access of scheduler
  # def prevent_access_from_unauth
  #   role = current_user.role
  #   if role.casecmp(ROLE[0]) == 0
  #     render :json => {:restricted => "user unauthorized"}
  #   end
  # end

  # Filter to prevent delete expense from unauthorized users - Scheduler  Receptionist  Practitioner

  # def stop_delete_unauth
  #   role = current_user.role
  #   if role.casecmp(ROLE[1]) == 0 || role.casecmp(ROLE[2]) == 0
  #     render :json => {:restricted => "user unauthorized"}
  #   end
  # end

  def get_account_name(account_list, code)
    ac_name = nil
    account_list.each do |account|
      if account[:item_code] == code
        ac_name = account[:item_name]
      end
    end
    return ac_name
  end

end
