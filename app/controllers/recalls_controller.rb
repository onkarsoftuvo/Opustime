class RecallsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index  , :new , :get_recall_type_details]
  before_action :find_recall , :only => [:edit , :update , :destroy , :set_recall_set_date]
  before_action :find_patient , :only => [:index,:create ]
  before_filter :set_current_user , :only => [ :create , :edit , :update , :destroy ,:set_recall_set_date]

  load_and_authorize_resource param_method: :recall_params
  before_filter :load_permissions

  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  
  def index 
    recalls = @patient.recalls.active_recall.select("recalls.id , recalls.recall_on_date , recalls.notes , recalls.is_selected , recalls.recall_set_date ")
    result = []
    recalls.each do |recall|
      item = {}
      item[:id] = recall.id
      item[:recall_type_name] = recall.recall_type.name
      item[:recall_on_date] = recall.recall_on_date
      item[:notes] = recall.notes
      item[:is_selected] = recall.is_selected
      item[:recall_set_date] = recall.recall_set_date
      result << item
    end
    render :json=> { recalls: result } 
    
  end
  
  def new 
    result = {} 
    result[:recall_on_date] = nil
    result[:notes] = nil
    result[:is_selected] =  false
    result[:recall_set_date] = nil
    item = {}
    item[:id] = nil
    item[:recall_type_id] = nil
    result[:recall_types_recall_attributes] = item
    render :json=> { :recall=>  result }
  end
  
  def create
    unless @patient.nil?
      recall = @patient.recalls.new(recall_params)
      if recall.valid?
        recall.save
        result = {flag: true , id: recall.id}
        render :json=> result
      else
        show_error_json(recall.errors.messages)
      end
    else
      recall = Recall.new
      recall.errors.add(:patient , "Not found !")
      recall.valid?
      show_error_json(recall.errors.messages)  
    end
    
  end
  
  def show
    result ={}
    result[:id] = @recall.id
    result[:recall_on_date] = @recall.recall_on_date
    result[:notes] = @recall.notes
    result[:is_selected] = @recall.is_selected
    result[:recall_set_date] = @recall.recall_set_date
    item = {}
    item[:id] = @recall.recall_types_recall.id
    item[:recall_type_id] = @recall.recall_type.id
    result[:recall_types_recall_attributes] = item
    
    render :json=> { :recall=>  result }
  end
  
  def edit
    result ={}
    result[:id] = @recall.id
    result[:recall_on_date] = @recall.recall_on_date
    result[:notes] = @recall.notes
    item = {}
    item[:id] = @recall.recall_types_recall.id
    item[:recall_type_id] = @recall.recall_type.id
    result[:recall_types_recall_attributes] = item
    
    render :json=> { :recall=>  result }
  end
  
  def update
    @recall.update_attributes(recall_params)
    if @recall.valid?
      result ={flag: true , id: @recall.id}
      render :json=> result  
    else
      show_error_json(@recall.errors.messages) 
    end
  end
  
  def destroy
    @recall.update_attributes(:status=> false )
    if @recall.valid?
      result ={flag: true , id: @recall.id}
      render :json=> result  
    else
      show_error_json(@recall.errors.messages) 
    end
    
  end
  
  def get_recall_type_details
    result = {}
    recall_type = @company.recall_types.active_recall.find(params[:id]) rescue nil
    unless recall_type.nil?
      result[:id] = recall_type.id
      result[:name] = recall_type.name
      result[:period_name] = recall_type.period_name.split("(")[0]
      result[:period_val] = recall_type.period_val  
    end 
    render :json=> result  
  end
  
  def set_recall_set_date
    if params[:is_selected].to_bool
      @recall.update_attributes(is_selected: params[:is_selected].to_bool, :recall_set_date => Date.today )
    else
      @recall.update_attributes(is_selected: params[:is_selected].to_bool, :recall_set_date => nil)
    end
    if @recall.valid?
      result ={flag: true , id: @recall.id}
      render :json=> result  
    else
      show_error_json(@recall.errors.messages) 
    end
  end
  
  def set_current_user
    Recall.current = current_user
  end
  
  private 
  
  def recall_params
    params.require(:recall).permit(:id , :recall_on_date , :notes , :is_selected , :recall_set_date , :recall_types_recall_attributes=> [:id , :recall_type_id])
  end
  
  def find_recall
   @recall = Recall.find(params[:id]) rescue nil 
  end
  
  def find_patient
     @patient = Patient.find(params[:patient_id]) rescue nil
   end
  
  
end
