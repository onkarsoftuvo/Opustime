class RecallTypesController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :create ]
  before_action :find_recall_type , :only =>[:edit , :update ,:destroy]

  load_and_authorize_resource param_method: :recall_type_params , :except=>[:index]
  before_filter :load_permissions
  
  def index 
    recall_types = @company.recall_types.select('recall_types.id , name, period_name , period_val')
    render :json=> recall_types
  end
  
  def create
    recall_type = @company.recall_types.new(recall_type_params)
    if recall_type.valid?
      recall_type.save
      result = {flag: true , id: recall_type.id}
      render :json=> result 
    else
      show_error_json(recall_type.errors.messages)
    end
  end
  
  def edit 
    render :json=> @recall_type
  end
  
  def update
    @recall_type.update_attributes(recall_type_params)
    if @recall_type.valid?
      @recall_type.save
      result = {flag: true , id: @recall_type.id}
      render :json=> result 
    else
      show_error_json(@recall_type.errors.messages)
    end
  end
  
  def destroy
    @recall_type.destroy
    render :json=>{flag: true}
  end

  def check_security_role
    result = {}
    result[:add] = can? :index , RecallType
    result[:modify] = can? :edit , RecallType
    result[:delete] = can? :destroy , RecallType
    render :json => result
  end


  
  private
  
  def find_recall_type
    @recall_type = RecallType.select("id, name , period_name , period_val ").find(params[:id]) rescue nil
  end
  
  def recall_type_params
    params.require(:recall_type).permit(:id , :name , :period_name , :period_val)
  end
  
end
