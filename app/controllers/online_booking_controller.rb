class OnlineBookingController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:edit , :create, :update ]
  before_action :check_business_details, :only =>[:update]
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  load_and_authorize_resource  param_method: :online_booking_params
  before_filter :load_permissions
  
  def edit
    online_booking = @company.online_booking
    result = {}
    result[:id] = online_booking.id
    result[:allow_online] = online_booking.allow_online
    result[:show_address] = request.base_url.to_s + '/booking'
    result[:ga_code] = online_booking.ga_code
    result[:min_appointment] = online_booking.min_appointment
    result[:advance_booking_time] = online_booking.advance_booking_time
    result[:min_cancel_appoint_time] = online_booking.min_cancel_appoint_time
    result[:notify_by] = online_booking.notify_by
    result[:show_price] = online_booking.show_price
    result[:hide_end_time] = online_booking.hide_end_time
    result[:req_patient_addr] = online_booking.req_patient_addr
    result[:time_sel_info] = online_booking.time_sel_info
    result[:terms] = online_booking.terms
    result[:logo] = online_booking.logo
    result[:show_dob] = online_booking.show_dob
    render :json=> result
  end
  
 
  def update
    result = {flag: true}
    businesses = @company.businesses
    if params[:allow_online]==true
      businesses.each do |bus|
        bus.update_column(:online_booking, true)
      end
    else
      businesses.each do |bus|
        bus.update_column(:online_booking, false)
      end
    end
    if params[:allow_online]==true && @flag == true
      temp_obj = OnlineBooking.new
      temp_obj.errors.add(:all_businesses , "must be fulfilled for online booking.")
      show_error_json(temp_obj.errors.messages)
    else
      begin
        online_booking_obj = OnlineBooking.find(params[:id])
 
        online_booking_obj.update_attributes(online_booking_params)
        # businesses = @company.businesses
        # raise businesses.inspect
        if online_booking_obj.valid?

          render :json=> {flag: true}    
        else
          show_error_json(online_booking_obj.errors.messages)
        end
      rescue Exception=> e
        res  = {error: e.message }
        render :json=> res     
      end
   end 
  end
  
  def upload
    
    if params[:allow_online]==true && @flag == true
      business = Business.new
      business.errors.add(:all_businesses , "need full details provided if online bookings is enabled. Please fix this on the business information page")
      show_error_json(business.errors.messages)
    else
      online_booking_obj = OnlineBooking.find(params[:id])
      logo = params[:file]
      online_booking_obj.update(:logo=> logo) unless logo.blank?
      if online_booking_obj.valid?
        render :json=> {flag: true}    
      else
        show_error_json(online_booking_obj.errors.messages)
      end
    end
  end
  
 
  private
  
  def online_booking_params
    params.require(:online_booking).permit(:id , :allow_online, :show_address , :ga_code , :min_appointment , :advance_booking_time , :min_cancel_appoint_time , :notify_by, :show_price, :hide_end_time, :req_patient_addr , :time_sel_info, :terms, :logo, :show_dob).tap do |whitelisted|
      whitelisted[:show_address] = "http://192.155.69.240/onlinebooking"  # It has to change later for only booking functionality 
    end
  end

  def get_online_booking_path
    unless request.base_url.include?('www')
      splitted_path = request.base_url.split('//')
      login_path = splitted_path[0] + '//' + @company.company_name.to_s.downcase + '.' + splitted_path[1] + '/booking'
    else
      login_path = request.base_url.gsub('www', "www.#{@company.company_name.to_s.downcase}") + '/booking'
    end
    # request.base_url.to_s+"/booking?comp_id=#{session[:comp_id]}"
    return login_path
  end

  protected
   def check_business_details
    @flag = false
    detail =  @company.businesses.where(:online_booking => true).select("id , name , address , web_url , online_booking , city , state , pin_code , country , reg_name , reg_number")
      detail.each do |bs|
        if bs.name.nil? 
          @flag = true
          break
        end
        # if bs.address.nil?
        #   @flag = true
        #   break
        # end
        # if bs.web_url.nil?
        #   @flag = true
        #   break
        # end
        # if bs.online_booking.nil?
        #   @flag =true
        #   break
        # end
        # if bs.city.nil?
        #   @flag = true
        #   break
        # end
        # if bs.state.nil?
        #   @flag = true
        #   break
        # end
        # if bs.pin_code.nil?
        #   @flag = true
        #   break
        # end
        # if bs.country.nil?
        #   @flag = true
        #   break
        # end
        # if bs.reg_name.nil?
        #   @flag = true
        #   break
        # end
        # if bs.reg_number.nil?
        #   @flag = true
        #   break
        # end
    end
   
  end
  
  
end
