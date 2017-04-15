class ConcessionTypeController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :new  , :create ]
  before_action :find_concession_type , :only =>[:edit , :update  , :destroy]
  before_filter :check_authorization , except: [:index]

  def index 
    concessions = @company.concessions.select("id , name")
    render :json=>concessions
    
  end
  
  def new 
    render :json=> :nothing
  end
  
  def create
    concession = @company.concessions.build(concession_type_params)
    if concession.valid?
      concession.save
      result = {:flag=> true , :concession_id => concession.id}
      render :json=> result
    else
      show_error_json(concession.errors.messages) 
    end
    
  end
  
  def edit  
    begin
      result = {}
      result[:id] = @concession.id
      result[:name] = @concession.name 
    rescue
      result= {}
    end
    
    render :json=> result    
  end
  
  def update
    begin
      @concession.update_attributes(concession_type_params)
      if @concession.valid?
        render :json=> true  
      else
        show_error_json(@concession.errors.messages)   
      end
    rescue Exception=> e
      render :json=> {flag: false , error: e.message}  
    end
    
  end
  
  def destroy
    flag = @concession.destroy
    render :json=> {flag: flag}
  end
  
  private

  def check_authorization
    authorize! :manage , Concession
  end
  
  def find_concession_type
    @concession = Concession.find(params[:id])
  end
  
  def concession_type_params
    params.require(:concession_type).permit(:id , :name)
  end
    
  
  
end
