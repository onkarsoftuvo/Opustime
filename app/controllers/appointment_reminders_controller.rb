class AppointmentRemindersController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:edit]
  before_action  :find_appointment_reminder, :only => [:edit]

  load_and_authorize_resource  param_method: :appointment_reminder_params
  before_filter :load_permissions

  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  # def index
    # appointment_reminder = AppointmentReminder.where(["company_id= ?", @company.id]).specific_attributes
    # render json: appointment_reminder
#   
  # end

  def edit
    appointment_reminder = @appointment_reminder.specific_attributes.first
    result = {}
    result["appointment_reminder"] = appointment_reminder
    render json: result 
  end

  def update
    appointment_reminder = AppointmentReminder.where(id: params[:id]).first
    appointment_reminder.update(appointment_reminder_params)
    if appointment_reminder.valid?
       result = {flag: true }
       render json: result  
    else 
      show_error_json(appointment_reminder.errors.messages)
    end
  end

  # def destroy
    # appointment_reminder = @appointment_reminder.first
    # if appointment_reminder.valid?
       # result = {flag: true }
       # render json: result  
    # else 
      # show_error_json(appointment_reminder.errors.messages)
    # end   
  # end

private
  
  def appointment_reminder_params
    params.require(:appointment_reminder).permit(:id, :d_reminder_type, :reminder_time, :skip_weekends, :reminder_period,
                :apply_reminder_type_to_all, :ac_email_subject, :ac_email_content,
                :ac_app_can_show, :hide_address_show, :reminder_email_subject,
                :reminder_email_enabled, :reminder_email_content, :reminder_app_can_show,
                :sms_enabled, :sms_text, :sms_app_can_show, :status )
  end
 
  def find_appointment_reminder
    @appointment_reminder = AppointmentReminder.where(company_id: @company.id)
  end

end


# {
  # "appointment_reminder": {
    # "id": 2,
    # "d_reminder_type": "SMS & Email",
    # "reminder_time": "1",
    # "skip_weekends": false,
    # "reminder_period": "10",
    # "apply_reminder_type_to_all": false,
    # "ac_email_subject": "Appointment - {{Business.Name}}",
    # "ac_email_content": null,
    # "ac_app_can_show": false,
    # "hide_address_show": false,
    # "reminder_email_subject": "Appointment Reminder",
    # "reminder_email_enabled": false,
    # "reminder_email_content": null,
    # "reminder_app_can_show": false,
    # "sms_enabled": false,
    # "sms_text": null,
    # "sms_app_can_show": false
  # }
# }
