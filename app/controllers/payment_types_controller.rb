class PaymentTypesController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :new  , :create ]
  
  before_action :find_payment_type , :only =>[:edit , :update  ,:destroy]

  load_and_authorize_resource  param_method: :payment_type_params
  before_filter :load_permissions
  
  # before_action :get_xero_gateway  , :only => [:xero_info_for_payment_type]
  
  def index
    payment_types = @company.payment_types.select("id , name")
    render :json=> payment_types  
  end
  
   
  def create 
    payment_type = @company.payment_types.build(payment_type_params)
    if payment_type.valid?
      payment_type.save
      result ={flag: true , :id=> payment_type.id }
      render :json => result 
    else
      show_error_json(payment_type.errors.messages)
    end 
    
  end
  
  def edit
    render :json => @payment_type
  end
  
  def update 
    @payment_type.update_attributes(payment_type_params)
    if @payment_type.valid?
      result = {flag: status }
      render :json=> result   
    else 
      show_error_json(@payment_type.errors.messages)
    end
    
    
  end
  
  def destroy
    unless @payment_type.name.casecmp("Cash")  == 0 
      if @payment_type.destroy
        render :json=>{flag: true}
      else
        show_error_json(@payment_type.errors.messages , flag= false)
      end
    else
      payment_type =PaymentType.new(:name=> "invalid")
      payment_type.errors.add(:cash ," payment type is not deletable! ")
      show_error_json(payment_type.errors.messages , flag= false)
    end
  end
  
  # def xero_info_for_payment_type
  #   xero_model = @company.xero_session
  #   result = {flag: false }
  #   unless xero_model.nil?
  #     if xero_model.is_connected
  #       result = {}
  #       result[:is_connected] = xero_model.is_connected
  #
  #     result[:payment_types_list] = get_payment_types_list(@xero_gateway)
  #     end
  #   end
  #   render :json=> result
  # end
  
  private 
  
  def payment_type_params
    params.require(:payment_type).permit(:id , :name )
  end
  
  def find_payment_type
    @payment_type = PaymentType.select("id , name ").find(params[:id])
  end
  
end
