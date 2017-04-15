class ExpensesController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain
  before_action :find_expense , :only => [:edit , :update , :destroy]

  before_action :stop_activity
  
# Filters for grant permission to users as per their role  
#   before_action :prevent_access_from_unauth
#   before_action :stop_delete_unauth , :only => [:destroy]
  before_action :set_params_format , :only => [:create , :update]

  
# filter to make able current user in model ExpenseProduct
  before_filter :set_current_user , :only => [ :create , :edit , :update , :destroy]

  load_and_authorize_resource  param_method: :params_expense
  before_filter :load_permissions

# using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  
  def search
    if current_user.user_role.try(:name).eql?(ROLE[5])
      expenses  = @company.expenses.active_expense.order("created_at desc").where(["expenses.vendor LIKE ? OR  expenses.category LIKE ? OR expenses.total_expense LIKE ? " , "%#{params[:q]}%" , "%#{params[:q]}%" , "%#{params[:q]}%"]).paginate(:page => params[:page])
    else
      expenses  = current_user.expenses.active_expense.order("created_at desc").where(["expenses.vendor LIKE ? OR  expenses.category LIKE ? OR expenses.total_expense LIKE ? " , "%#{params[:q]}%" , "%#{params[:q]}%" , "%#{params[:q]}%"]).paginate(:page => params[:page])
    end

    render :json=> {:expense=> expenses }
  end
  
  def index
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : Expense.per_page
    if current_user.user_role.try(:name).eql?(ROLE[5])
      unless params[:q].blank? || params[:q].nil?
        expenses  = @company.expenses.active_expense.joins(:expense_category , :expense_vendor).order("created_at desc").where(["expense_vendors.name LIKE ? OR  expense_categories.name LIKE ? OR expenses.total_expense LIKE ? " , "%#{params[:q]}%" , "%#{params[:q]}%" , "%#{params[:q]}%"]).paginate(:page => params[:page] , per_page: per_page)
      else
        expenses  = @company.expenses.active_expense.order("created_at desc").paginate(:page => params[:page] , per_page: per_page )
      end
    else
      unless params[:q].blank? || params[:q].nil?
        expenses  = current_user.expenses.active_expense.joins(:expense_category , :expense_vendor).order("created_at desc").where(["expense_vendors.name LIKE ? OR  expense_categories.name LIKE ? OR expenses.total_expense LIKE ? " , "%#{params[:q]}%" , "%#{params[:q]}%" , "%#{params[:q]}%"]).paginate(:page => params[:page] , per_page: per_page )
      else
        expenses  = current_user.expenses.active_expense.order("created_at desc").paginate(:page => params[:page] , per_page: per_page)
      end
    end

    result = []
     
    expenses.each do |exp|
      item = {}
      item[:id] = exp.id
      item[:expense_date] = exp.expense_date
      item[:vendor] = exp.expense_vendor.try(:name)
      item[:category] = exp.expense_category.try(:name)
      item[:total_expense] = '% .2f'% (exp.total_expense).to_f
      item[:total_expense] = '% .2f'% (exp.total_expense.to_f)
      result << item
    end

    render :json=> {:expense=> result , total: expenses.count }
  end
  
  def new 
        
  end
  
  def create
#	handling invalid product
    check_valid_product(params)
#   handling that case if product is available in params and including product option is false
    params[:expense][:expense_products_attributes]=nil  if params[:expense]["include_product_price"] == false || params[:expense]["include_product_price"] == "false" 
    expense = @company.expenses.new(params_expense)

    if expense.valid?
      expense.set_created_by(current_user.id)
      expense.with_lock do
        expense.save
      end


      # Adding ACtivity log for dashbaord      
      Expense.public_activity_on
      expense.create_activity :create , parameters: {total_amount: expense.total_expense , :include_tax=> expense.tax_amount > 0 , bs_id: expense.business.try(:id) , bs_name: expense.business.try(:name) } 

      result = {flag: true }
      render :json => result 
    else
      show_error_json(expense.errors.messages)
    end
    
  end
  
  def edit
    begin
      item = {}
      item[:id] = @expense.id
      item[:business_name] = @expense.business.try(:id).to_s
      item[:expense_date] = @expense.expense_date
      item[:expense_account_ref] = @expense.expense_account_ref.to_s
      vendor_item = {}
      if @expense.expense_vendor.nil?
        vendor_item = nil
      else
        vendor_item[:id] = @expense.expense_vendor.id
        vendor_item[:name] = @expense.expense_vendor.name
      end

      category_item = {}
      if @expense.expense_category.nil?
        category_item = nil
      else
        category_item[:id] = @expense.expense_category.id
        category_item[:name] = @expense.expense_category.name
      end
      item[:vendor] = vendor_item
      item[:category] = category_item
      item[:total_expense] = (@expense.total_expense)
      item[:tax] = @expense.tax
      item[:tax_amount] = @expense.tax_amount
      item[:note] = @expense.note 
      item[:include_product_price] = @expense.include_product_price
      item[:sub_amount] =  (@expense.sub_amount.to_f)
      item[:created_by] = @expense.created_by
      item[:expense_products_attributes] = [] 
      @expense.expense_products.each do |exp_product|
        exp_product_item = {} 
        exp_product_item[:id] = exp_product.id
        exp_product_item[:prod_id] = exp_product.prod_id 
        exp_product_item[:name] = exp_product.name
        exp_product_item[:unit_cost_price] = exp_product.unit_cost_price
        exp_product_item[:quantity] = exp_product.quantity
        item[:expense_products_attributes] << exp_product_item 
      end
      item[:next] = @expense.next_expense
      item[:prev] = @expense.prev_expense
      render :json=> item
    rescue Exception=> e
      @expense.errors.add(:base , e.message)
      show_error_json(@expense.errors.messages)
      
    end
  end
  
  def update
    begin
#     handling invalid product in expense 
      check_valid_product(params) 
#     handling that case if product is available in params and including product option is false  
      params[:expense][:expense_products_attributes] = nil  if params[:expense]["include_product_price"] == false || params[:expense]["include_product_price"] == "false"
      
#     method to add _destroy:true  into params
      add_destory_key_to_params(params) 
      @expense.update(params_expense)
      if @expense.valid?
        Expense.public_activity_on
        @expense.create_activity :update , parameters: {total_amount: @expense.total_expense , :include_tax=> @expense.tax_amount.to_i > 0 , bs_id: @expense.business.try(:id) , bs_name: @expense.business.try(:name)} #, :other => @expense.update_activity_log }
        result = {flag: true }
        render :json => result 
      else
        show_error_json(@expense.errors.messages)
      end
    rescue Exception=> e
      @expense.errors.add(:base , e.message)
      show_error_json(@expense.errors.messages)
    end
  end
  
  def destroy
    @expense.update_column(:status,"deactive")
    if @expense.valid?
      Expense.public_activity_on
      @expense.create_activity :delete
      transaction = Intuit::OpustimeTransactionDelete.new(@expense.id, @expense.class, $token, $secret, $realm_id)  if $qbo_credentials.present?
      transaction.sync_delete
      result = { flag: true } 
    else
      result = { flag: false }
    end
    render :json => result
    
  end
  
  def vendors_list
    vendors = @company.expenses.map(&:vendor).uniq
    render :json => vendors
  end
  
  def category_list
    categories = @company.expenses.map(&:category).uniq
    render :json => categories
  end
  
  def product_list
    products = @company.products.active_products
    prod_list  = []
    products.each do |item|
      new_item = {}
      new_item["prod_id"] = item.id
      new_item["name"] = item.name
      prod_list << new_item
    end
    render :json => prod_list
  end

  def categories_list_from_model
    result = @company.expense_categories.select("id , name")
    render :json => result
  end

  def vendors_list_from_model
    result = @company.expense_vendors.select("id , name")
    render :json=> result
  end

  def check_security_role
    result = {}
    result[:view] = can? :index , Expense
    result[:create] = can? :create , Expense
    result[:modify] = can? :update , Expense
    result[:delete] = can? :destroy , Expense
    render :json => result
  end
  
  
  
  private
  
#  adding _destroy:true into params for deleting record      
  def add_destory_key_to_params(params)
      if params[:expense][:expense_products_attributes].nil?
        params[:expense][:expense_products_attributes] = []
        params[:expense][:include_product_price] = false  
      end
       
      expense_product_ids = params[:expense][:expense_products_attributes].map{|k| k["id"]}
      all_expense_product_ids = @expense.expense_products.map(&:id)
      
      exp_prod_deleteable = all_expense_product_ids - expense_product_ids
      
      exp_prod_deleteable.each do |id|
        exp_product = ExpenseProduct.find(id)
        exp_product_item = {} 
        exp_product_item[:id] = exp_product.id
        exp_product_item[:prod_id] = exp_product.prod_id 
        exp_product_item[:name] = exp_product.name
        exp_product_item[:unit_cost_price] = exp_product.unit_cost_price
        exp_product_item[:quantity] = exp_product.quantity
        exp_product_item[:_destroy] = true
        params[:expense][:expense_products_attributes] << exp_product_item 
      end
  end
#     Over here
  def check_valid_product(params)
    unless params[:expense][:expense_products_attributes].nil?
      params[:expense][:expense_products_attributes].each do |item|
        if item["prod_id"].blank?
          params[:expense][:expense_products_attributes].delete(item)    
        end
      end
    end  
  end
  
  def set_current_user
    ExpenseProduct.current = current_user
  end
  
# Filter to prevent access of scheduler 
  def prevent_access_from_unauth
    role = current_user.role
    if role.casecmp(ROLE[0]) == 0
      render :json=> {:restricted=>"user unauthorized"}
    end
  end
  
# Filter to prevent delete expense from unauthorized users - Scheduler  Receptionist  Practitioner

  def stop_delete_unauth
    role = current_user.role
    if role.casecmp(ROLE[1]) == 0 || role.casecmp(ROLE[2]) == 0
      render :json=> {:restricted=>"user unauthorized"}
    end
  end  
  
  def params_expense
    params.require(:expense).permit(:id , :expense_date , :business_name , :vendor , :category , :total_expense ,:expense_account_ref, :tax , :tax_amount , :note , :include_product_price , :created_by, :sub_amount ,
      :expense_products_attributes => [:id , :prod_id , :name , :unit_cost_price , :quantity , :_destroy] ,
      :expense_categories_expense_attributes => [:id , :expense_id , :expense_category_id , :_destroy] ,
      :expense_vendors_expense_attributes => [:id , :expense_id , :expense_vendor_id , :_destroy] ,
      :businesses_expense_attributes => [:id , :expense_id , :business_id , :_destroy] 

      ).tap do |whilelisted|
      whilelisted[:user_id] = current_user.id
    end
  end
  
  def find_expense
    @expense = @company.expenses.find_by_id(params[:id])
  end

  def set_params_format
    
    unless params[:expense][:id].present?
      # For category insertion 
      unless params[:expense][:category].nil? && params[:expense][:category][:name].present?
        if params[:expense][:category][:id].present?
          expense_category = @company.expense_categories.find_by_id(params[:expense][:category][:id])
          expense_category = @company.expense_categories.create(:name=> params[:expense][:category][:name] ) if expense_category.nil?           
        else
          expense_category = @company.expense_categories.create(:name=> params[:expense][:category][:name] )          
        end
        
        item = {}
        item[:expense_category_id] = expense_category.try(:id)
        params[:expense][:expense_categories_expense_attributes] = item
      end

      # For vendor insertion

      unless params[:expense][:vendor].nil? && params[:expense][:vendor][:name].present?
        if params[:expense][:vendor][:id].present?
          expense_vendor = @company.expense_vendors.find_by_id(params[:expense][:vendor][:id])
          expense_vendor = @company.expense_vendors.create(:name=> params[:expense][:vendor][:name] ) if expense_vendor.nil?           
        else
          expense_vendor = @company.expense_vendors.create(:name=> params[:expense][:vendor][:name] )
        end

        item = {}
        item[:expense_vendor_id] = expense_vendor.id
        params[:expense][:expense_vendors_expense_attributes] = item
      end
    else
      expense_categories_expense = @expense.expense_categories_expense
      expense_vendors_expense = @expense.expense_vendors_expense
      # For category insertion 
      unless params[:expense][:category].nil? && params[:expense][:category][:name].present?
        if params[:expense][:category][:id].present?
          expense_category = @company.expense_categories.find_by_id(params[:expense][:category][:id])
          expense_category = @company.expense_categories.create(:name=> params[:expense][:category][:name] ) if expense_category.nil?           
        else
          expense_category = @company.expense_categories.create(:name=> params[:expense][:category][:name] )          
        end
        
        item = {}
        item[:id] = expense_categories_expense.try(:id)
        item[:expense_category_id] = expense_category.try(:id)
        params[:expense][:expense_categories_expense_attributes] = item
      else
        unless expense_categories_expense.nil?
          item = {}
          item[:id] = expense_categories_expense.try(:id)
          item[:_destroy] = true
          params[:expense][:expense_categories_expense_attributes] = item  
        end
      end

      # For vendor insertion

      unless params[:expense][:vendor].nil? && params[:expense][:vendor][:name].present?
        if params[:expense][:vendor][:id].present?
          expense_vendor = @company.expense_vendors.find_by_id(params[:expense][:vendor][:id])
          expense_vendor = @company.expense_vendors.create(:name=> params[:expense][:vendor][:name] ) if expense_vendor.nil?           
        else
          expense_vendor = @company.expense_vendors.create(:name=> params[:expense][:vendor][:name] )
        end

        item = {}
        item[:id] = expense_vendors_expense.try(:id)
        item[:expense_vendor_id] = expense_vendor.id
        params[:expense][:expense_vendors_expense_attributes] = item
      else
        unless expense_vendors_expense.nil?
          item = {}
          item[:id] = expense_vendors_expense.try(:id)
          item[:_destroy] = true
          params[:expense][:expense_vendors_expense_attributes] = item
        end

      end
    end

    # Setting business parameter in separate model 
    if params[:expense]["business_name"].present?
      item = {}  
      item[:business_id] = params[:expense]["business_name"]
      params[:expense][:businesses_expense_attributes] = item
    end 
  end

  def stop_activity
    Expense.public_activity_off
  end


end
