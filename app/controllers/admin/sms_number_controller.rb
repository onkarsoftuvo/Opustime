class Admin::SmsNumberController < ApplicationController
  before_action :admin_authorize

  def edit
    @sms_number= SmsNumber.find(params[:id])
  end

  def update
    @sms_number = SmsNumber.find(params[:id])
    respond_to do |format|
      if @sms_number.update_attributes(set_params)
        format.html { redirect_to sms_number_path, notice: 'SMS Number was successfully Updated.' }
      else
        format.html { redirect_to sms_number_path, notice: 'Something went wrong.' }
      end
  end
  end

  private
  def set_params
    params.require(:sms_number).permit(:company_id, :number)
  end

end
