class ReferralTypesController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :create , :new , :referral ]
  before_action :find_referral_type , :only => [:edit , :update , :destroy]

  # load_and_authorize_resource  param_method: :referral_type_params , except: [:referral , :index]
  # before_filter :load_permissions

  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    referral_types = @company.referral_types.order("created_at desc").active_referral_type.select("id, referral_source , status")
    render json: referral_types
  end

  def new
    authorize! :manage , ReferralType
    referral_type  = ReferralType.new
    result = {}
    result[:referral_type] =  referral_type
    render :json =>  result
  end

  def create
    authorize! :manage , ReferralType
    referral_type = @company.referral_types.new(referral_type_params)
      if referral_type.valid?
         referral_type.save
         result = { flag: true, id: referral_type.id}
         render :json =>  result
      else
         show_error_json(referral_type.errors.messages) 
      end
  end

  def edit
    authorize! :manage , ReferralType
    referral_type =  @referral_type.specific_attributes.first
    result  = {}
    result[:id] = referral_type.id
    result[:referral_source] = referral_type.referral_source
    result[:referral_type_subcats_attributes]  = []
    referral_type.referral_type_subcats.each do |sub_cat|
      item = {}
      item[:id] = sub_cat.id
      item[:sub_name] = sub_cat.sub_name
      result[:referral_type_subcats_attributes] << item
    end
    render :json => result  
  end

  def update
    authorize! :manage , ReferralType
    referral_type = @referral_type.first

   #  calling method to add _destroy params in deleted items
    add_destory_key_to_params(params , referral_type)
   
    referral_type.update(referral_type_params)
    if referral_type.valid?
       result = {flag: true }
       render json: result  
    else
        show_error_json(referral_type.errors.messages)
    end
  end

  def destroy
    authorize! :manage , ReferralType
    referral_type = @referral_type.first
    referral_type.update_attributes(:status=> false)
    if referral_type.valid?
      result = {flag: true }
      render json: result  
    else 
      show_error_json(referral_type.errors.messages)
    end   
  end
  
  def referral
    referral_types = @company.referral_types.order("created_at desc").active_referral_type.select("id, referral_source , status")
    result = []
    referral_types.each do |refer_item|
      item = {}
      item[:id] = refer_item.id
      item[:referral_source] = refer_item.referral_source
      item[:referral_type_subcats] = []
      refer_item.referral_type_subcats.each do |sub_cat|
        sub_cat_item  = {}
        sub_cat_item[:id] = sub_cat.id
        sub_cat_item[:sub_name] = sub_cat.sub_name
        item[:referral_type_subcats] << sub_cat_item 
      end 
      result << item 
    end
    render json: result  
  end

  private

  def referral_type_params
    params.require(:referral_type).permit(:id , :referral_source , referral_type_subcats_attributes:[:id , :sub_name , :_destroy])
  end
 
  def find_referral_type
    @referral_type = ReferralType.where(:id=> params[:id])
  end
  
  #  adding _destroy:true into params for deleting record      
  def add_destory_key_to_params(params , referral_type)
      all_referral_subcat_ids = referral_type.referral_type_subcats.map(&:id) 
      unless params[:referral_type][:referral_type_subcats_attributes].nil?
        referral_subcat_ids = params[:referral_type][:referral_type_subcats_attributes].map{|k| k["id"]}
        refer_subcat_deleteable = all_referral_subcat_ids - referral_subcat_ids  
      else
        params[:referral_type][:referral_type_subcats_attributes] = []
        refer_subcat_deleteable = all_referral_subcat_ids
      end
      
      
      refer_subcat_deleteable.each do |id|
        referral_subcat = ReferralTypeSubcat.find(id)
        refer_subcat_item = {} 
        refer_subcat_item[:id] = referral_subcat.id
        refer_subcat_item[:sub_name] = referral_subcat.sub_name
        refer_subcat_item[:_destroy] = true
        params[:referral_type][:referral_type_subcats_attributes] << refer_subcat_item 
      end
  end
#     Over here

end