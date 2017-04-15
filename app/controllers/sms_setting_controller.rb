class SmsSettingController < ApplicationController
  include Plivo
  respond_to :json
  before_filter :authorize , :except=> [:receive_sms]
  before_filter :set_rest_api
  before_action :find_company_by_sub_domain , :only =>[:edit , :update]

  load_and_authorize_resource  param_method: :sms_setting_params
  before_filter :load_permissions
  
# using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def edit
    sms_setting = @company.sms_setting
    sms_setting_detail = {id: sms_setting.id, sms_alert_no: sms_setting.sms_alert_no , mob_no: sms_setting.mob_no , email: sms_setting.email ,  default_sms: sms_setting.default_sms }
    exist_in_sms_group = SmsGroupCountry.find_by_country(@company.country)
    if exist_in_sms_group.present?
      sms_plans =SmsPlan.active_sms_plan.select("id, amount , no_sms").where(sms_group_id: exist_in_sms_group.sms_group_id)
    else
      default_sms_group = SmsGroup.find_by(name: 'default')
      sms_plans = SmsPlan.active_sms_plan.select("id, amount , no_sms").where(sms_group_id: default_sms_group.id)
    end
    result = { sms_setting_detail: sms_setting_detail , sms_plans: sms_plans } 
    render :json=> result  
  end
  
  def update
    sms_setting = SmsSetting.find(params[:sms_setting][:id])
    sms_setting.update(sms_setting_params)
    if sms_setting.valid?
      result = {flag: true , sms_setting_id: sms_setting.id}
      render :json=> result
     else 
      show_error_json(sms_setting.errors.messages)    
     end
    
  end

  def send_sms

    # src_no = '+5078481068'
    # # src_no = '+12266462173'
    # dst_no = '+919501222018'

    # params = {
    #     'src' => src_no ,  # Sender's phone number with country code
    #     'dst' => dst_no , # Receivers' phone numbers with country code. The numbers are separated by "<" delimiter.
    #     'text' => 'Hi , Greeting msg from plivo' # Your SMS Text Message - English
    # }

    # response = @rest_api.send_message(params)

    # if response[0] == 202
    #   render :json=> {flag: true , :msg=> "Msg has been sent successfully!"}
    # else
    #   render :json=> {flag: false , :msg=> "Msg does not send."}
    # end

    src_no = '+12266462173'
    dst_no = '+12045152646'

    params = {
        'src' => src_no ,  # Sender's phone number with country code
        'dst' => dst_no , # Receivers' phone numbers with country code. The numbers are separated by "<" delimiter.
        'text' => 'Hi , Greeting msg from plivo' # Your SMS Text Message - English
    }
    response = @rest_api.send_message(params)
    
    if response[0] == 202
      render :json=> {flag: true , :msg=> "Msg has been sent successfully!"}
    else
      render :json=> {flag: false , :msg=> "Msg does not send."}
    end

  end

  def receive_sms
    # Temp.create(sms: params)  # create a model in which receive msg info will be stored.
    
    result = params
    render :json => result

  end

  def check_temp
    @temp = {}    #Temp.last
    render :json=> {data: @temp }

  end
  
  private 

  def sms_setting_params
    params.require(:sms_setting).permit(:id , :sms_alert_no , :mob_no , :email , :default_sms)
  end

  def set_rest_api
    @rest_api = RestAPI.new(CONFIG[:plivo_access_id], CONFIG[:plivo_secret_id])
  end
  
end
