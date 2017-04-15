class MedicalAlertsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_patient , :only => [:index , :create]
  before_action :find_medical_alert , :only=> [:edit , :update , :destroy]

  # load_and_authorize_resource  param_method: :medical_alert_params
  # before_filter :load_permissions
  
   # using only for postman to test API. Remove later  
    skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
    
  def index
    patient = @patient.first
    medical_alerts= patient.medical_alerts.select("id , alertName")
    result = {medical_alerts: medical_alerts}
    render :json=> result
  end 
  
  def create
    authorize! :manage , MedicalAlert
    patient = @patient.first
    md_alert = patient.medical_alerts.new(medical_alert_params)
    if md_alert.valid?
      md_alert.save
      result = {flag: true  }
      render :json=> result
    else 
      show_error_json(md_alert.errors.messages)
    end
  end
  
  def edit
    authorize! :manage , MedicalAlert
    render :json=> @medical_alert.select("id , alertName")
  end
  
  def update
    authorize! :manage , MedicalAlert
    medical_alert = @medical_alert.first  
    medical_alert.update_attributes(medical_alert_params)
    if medical_alert.valid?
      result = {flag: true  }
      render :json=> result
    else 
      show_error_json(medical_alert.errors.messages)
    end
  end
  
  def destroy
    authorize! :manage , MedicalAlert
    item  = @medical_alert.first.destroy
    if item.valid?
      result = {flag: true  }
      render :json=> result
    else 
      show_error_json(item.errors.messages)
    end
  end
  
  private
  
  def medical_alert_params
    params.require(:medical_alert).permit(:id , :alertName)  
  end
  
  def find_patient
    @patient = Patient.where(:id=>params[:patient_id])
  end
  
  def find_medical_alert
    @medical_alert = MedicalAlert.where(:id=>params[:id])
  end
  
end

