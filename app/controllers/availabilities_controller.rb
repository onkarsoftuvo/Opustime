class AvailabilitiesController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :create , :new ]
  before_action :find_availability , :only => [:show , :edit , :update , :destroy , :update_partially ]
  before_action :find_doctor , :only =>[:create , :update]
  before_action :set_params_in_structured_format , :only =>[:create , :update , :update_partially]
  
  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  
  def index
    begin 
      result = []
      render :json => {availabilities: result}   
    rescue Exception => e
      render json => {:error=> e.message} 
    end
  end
  
  def create 
    begin 
      unless @practitioner.nil?
        if params[:availability][:repeat] == "week" && params[:availability][:week_days].length > 0
          flag = Availability.create_availability_weekly_days_wise(@practitioner , avail_params)
          result = {flag: flag}
          render :json=> result
        else
          avail  = @practitioner.availabilities.new(avail_params)
        
          if avail.valid?
            avail.unique_key = random_key
            avail.save
            result = {flag: true , id: avail.id }
            render :json=> result
          else
            show_error_json(avail.errors.messages)
          end  
        end    
      else
        avail = Availability.new
        avail.errors.add(:practitioner , "invalid !")
        show_error_json(avail.errors.messages)
      end
         
    rescue Exception => e
      render :json => {:error=> e.message} 
    end
  end
  
  def show
    unless @availability.nil?
      result = {}
      result[:id] = @availability.id
      result[:title] = "Unavailable"
      result[:practitioner_id] = @availability.user.try(:id)
      result[:practitioner] = @availability.user.full_name_with_title
      result[:which_date] = @availability.avail_date.strftime("%A, %d %B %Y")
      result[:at] = @availability.avail_time_start.strftime("%H:%M%P")
      result[:unavail_period] = @availability.time_check_format
      
      start_time = @availability.avail_time_start
      end_time = @availability.avail_time_end
      avail_time_duration = Time.diff(start_time , end_time)
      result[:appnt_duration_min] = (avail_time_duration[:hour].to_i * 60) + avail_time_duration[:minute]
       
      result[:notes] = @availability.notes
      result[:has_series] = @availability.has_series
      create_time = @availability.created_at.strftime("%d %b %Y,%H:%M%P")
      update_time = @availability.updated_at.strftime("%d %b %Y,%H:%M%P")
      if create_time == update_time
        result[:created_at] = create_time
        result[:updated_at] = nil
      else
        result[:updated_at] = update_time        
        result[:created_at] = nil
      end
      
      render :json=> result  
    else
      render :json => {:error=> "Invalid Availability !"} 
    end
  end
  
  def edit
    unless @availability.nil?
      result = {}
      result[:id] = @availability.id
      result[:user_id] = @availability.user.try(:id)
      result[:user_name] = @availability.user.try(:full_name)
      result[:avail_date] = @availability.avail_date.strftime("%Y-%m-%d")
      result[:start_hr] = @availability.avail_time_start.strftime("%H").to_i
      result[:start_min] = @availability.avail_time_start.strftime("%M").to_i
      result[:end_hr] = @availability.avail_time_end.strftime("%H").to_i
      result[:end_min] = @availability.avail_time_end.strftime("%M").to_i
      result[:repeat] = @availability.repeat
      result[:repeat_every] = @availability.repeat_every
      
      if @availability.repeat == "week"
        result[:ends_after] = @availability.get_total_week_no
      else
        result[:ends_after] = @availability.siblings_in_series  
      end
      
      result[:notes] = @availability.notes
      result[:has_series]  = @availability.has_series
      days_arr = @availability.week_days
      days_arr.map! { |x| x == 7 ? 0 : x }.flatten!
      result[:week_days]  = days_arr
      render :json=> { appointment:  result }
      
    else
      render :json => {:error=> "Invalid Availability !"} 
    end
    
    
    
  end
  
  def update
    if params[:availability][:flag].to_i == 0  || params[:availability][:flag].nil?
      if @availability.has_series || params[:availability][:repeat].nil?
        updated_params_avail = occurrence_parameters_same(@availability , avail_params)
        @availability.update_attributes(updated_params_avail)
        if @availability.valid?
          result = {:flag=> true , :id=> @availability.id}
          render :json=> result
        else 
          show_error_json(@availability.errors.messages)
        end 
      else
        params[:availability].delete "id" if  params[:availability]["id"].present?
        business = @availability.business
        @availability.destroy
        if params[:availability][:repeat] == "week" && params[:availability][:week_days].length > 0
          flag = Availability.create_availability_weekly_days_wise(@practitioner , avail_params , business )
          result = {flag: flag}
          render :json=> result
        else
          avail  = @practitioner.availabilities.new(avail_params)
          if avail.valid?
            avail.unique_key = random_key
            avail.business = business 
            avail.save
            result = {flag: true , id: avail.id }
            render :json=> result
          else
            show_error_json(avail.errors.messages)
          end  
        end 
      end
    elsif params[:availability][:flag].to_i == 1                # when following option is selected 
      series_item_no = params[:availability][:ends_after].to_i
      repeat_by_val = params[:availability][:repeat]
      
      # has same child availabilities 
      if @availability.has_same_item_series(series_item_no , repeat_by_val , params[:availability][:repeat_every] , params[:availability][:week_days])
        
        # checking repeat by value is same or not 
        if @availability.repeat.to_s.casecmp(params[:availability][:repeat]) == 0
            @availability.update_attributes(avail_params)
        
        if @availability.valid? 
          flag = @availability.reflect_same_in_all_following
          result = {:flag=> flag , :id=> @availability.id}
          render :json=> result
        else
          show_error_json(@availability.errors.messages)
        end              
        else
          params[:availability].delete "id" if  params[:availability]["id"].present?
          avail  = @practitioner.availabilities.new(avail_params)
          if avail.valid?
            business = @availability.business
            @availability.remove_following_including_itself
            
            if params[:availability][:repeat] == "week"
              flag = Availability.create_availability_weekly_days_wise(@practitioner , avail_params , business )
              result = {flag: flag}
              render :json=> result                
            else 
              flag = create_availability_manually(avail_params ,  business)
              render :json=> {flag: flag}  
            end
            
          else
            show_error_json(avail.errors.messages)
          end  
        end 
      else
        params[:availability].delete "id" if  params[:availability]["id"].present?
        avail  = @practitioner.availabilities.new(avail_params)
        if avail.valid?
          business = @availability.business
          @availability.remove_following_including_itself
          
          if params[:availability][:repeat] == "week"
            flag = Availability.create_availability_weekly_days_wise(@practitioner , avail_params , business )
            result = {flag: flag}
            render :json=> result                
          else 
            flag = create_availability_manually(avail_params ,  business)
            render :json=> {flag: flag}  
          end
        else
          show_error_json(avail.errors.messages)
        end
      end
        
    elsif params[:availability][:flag].to_i == 2
      series_item_no = params[:availability][:ends_after].to_i
      repeat_by_val = params[:availability][:repeat]
      if @availability.has_same_item_series(series_item_no , repeat_by_val , params[:availability][:repeat_every] , params[:availability][:week_days])
        
        if @availability.repeat.to_s.casecmp(params[:availability][:repeat])== 0
          if @availability.inverse_childavailability.nil?
            @availability.update_attributes(avail_params)
            flag = @availability.reflect_same_in_all_following
            render :json=> {flag: flag}    
          else
            @availability.update_attributes(avail_params)
            @availability.same_all_events_child
            render :json=> {flag: true}
          end
        else
          params[:availability].delete "id" if  params[:availability]["id"].present?
          avail  = @practitioner.availabilities.new(avail_params)
          if avail.valid?
            business = @availability.business
            @availability.remove_following_including_itself
            
            if params[:availability][:repeat] == "week"
              flag = Availability.create_availability_weekly_days_wise(@practitioner , avail_params , business )
              result = {flag: flag}
              render :json=> result                
            else 
              flag = create_availability_manually(avail_params ,  business)
              render :json=> {flag: flag}  
            end
          else
            show_error_json(avail.errors.messages)
          end  
        end     
      else 
        params[:availability].delete "id" if  params[:availability]["id"].present?
        avail  = @practitioner.availabilities.new(avail_params)
        if avail.valid?
          business = @availability.business
          @availability.remove_following_including_itself
          
          if params[:availability][:repeat] == "week"
            flag = Availability.create_availability_weekly_days_wise(@practitioner , avail_params , business )
            result = {flag: flag}
            render :json=> result                
          else 
            flag = create_availability_manually(avail_params ,  business)
            render :json=> {flag: flag}  
          end
        else
          show_error_json(avail.errors.messages)
        end
      end          
    end
  end
  
  # this action is handling - move , stretch , reschedule  
  def update_partially
    @availability.update_attributes(avail_params)
    if @availability.valid?
      result = {id: @availability.id , flag: true}
      render :json=> result 
    else
      show_error_json(@availability.errors.messages)
    end
  end
  
  def destroy
    if params[:flag].to_i == 0
        # if params[:appointment][:reason].nil?
          # @appointment.update_attributes(:status=> false)  
        # else
          # @appointment.update_attributes(:status=> false , :reason => params[:appointment][:reason])
        # end
        @availability.update_attributes(:status=> false)
        if @availability.valid?
          result = {flag: true , id: @availability.id }
          render :json=> result
        else
          show_error_json(@availability.errors.messages)
        end
      elsif params[:flag].to_i == 1
        @availability.status_change_itself_and_following_availabilities_for_delete
        result = {flag: true }
        render :json=> result
      elsif params[:flag].to_i == 2
        @availability.status_change_for_all_avails_in_series
        result = {flag: true  }
        render :json=> result
      end
  end
  
  private 
  
  def avail_params
    params.require(:availability).permit(:id , :avail_date, :avail_time_start, :avail_time_end ,  :notes, :repeat, :repeat_every, :ends_after , :is_block  , :user_id , 
      :availabilities_business_attributes => [:id , :business_id , :_destroy ]).tap do |whitelisted|
       whitelisted[:week_days] = params[:availability][:week_days] 
     end
  end
  
  def set_params_in_structured_format
    structure_format = {}
    start_hr = (params[:availability][:start_hr].nil? || params[:availability][:start_hr].blank?) ? "0" : params[:availability][:start_hr]
    start_min = (params[:availability][:start_min].nil? || params[:availability][:start_min].blank?) ? "0" : params[:availability][:start_min]
    start_time = start_hr.to_s + ":" + start_min.to_s 
    
    end_hr = (params[:availability][:end_hr].nil? || params[:availability][:end_hr].blank?) ? "0" : params[:availability][:end_hr]
    end_min = (params[:availability][:end_min].nil? || params[:availability][:end_min].blank?) ? "0" : params[:availability][:end_min]
    end_time = end_hr.to_s + ":"+ end_min.to_s 
  
    params[:availability][:avail_time_start] = start_time  unless start_time == "0:0"
    params[:availability][:avail_time_end] = end_time  unless end_time == "0:0"
    
    unless params[:business_id].nil?
      params[:availability][:availabilities_business_attributes] = { :business_id=> params[:business_id] }
    end
    
    unless params[:doctor_id].nil?
      params[:availability][:user_id] = params[:doctor_id] 
    end
    
    if params[:availability][:repeat] == "week"
      unless params[:availability][:week_days].nil? 
        params[:availability][:week_days] = params[:availability][:week_days]
      else
        params[:availability][:week_days] = []
        avail = Availability.new
        avail.errors.add(:week_day , "must be selected at least one.")
        show_error_json(avail.errors.messages)
        return false
      end
    else
      params[:availability][:week_days] = []
    end
    
  end
  
  def find_availability
    @availability = Availability.active_avail.find(params[:id]) rescue nil
  end
#   Method to create multiple availabilities by single one 
  def create_repeating_availabilities(avail_params)
    flag_run = true
    
    repeat_by = avail_params[:repeat]
    repeat_val = nil
    start_val = avail_params[:repeat_every].to_i
    end_val =  avail_params[:ends_after].to_i
    avail_ids = []
    
    if repeat_by.to_s.casecmp("day") == 0
      repeat_val = start_val.day
    elsif repeat_by.to_s.casecmp("week") == 0
      repeat_val = start_val.week
    elsif repeat_by.to_s.casecmp("month") == 0
      repeat_val = start_val.month
    end
    
    
    begin 
      if avail_params[:is_block].nil? || avail_params[:is_block]== false
        availability = @practitioner.availabilities.extra_avails.where(["DATE(avail_date) = ? AND avail_time_start = CAST(? AS time) AND avail_time_end = CAST(? AS time)" , avail_params[:avail_date].to_date , avail_params[:avail_time_start] , avail_params[:avail_time_end] ]).first
        if availability.nil?
          availability = @practitioner.availabilities.new(avail_params)
          if availability.valid?
            availability.save
            avail_ids << availability.id
            # result = {flag: true , id: availability.id}
            # render :json => {availabilities: result}    
          else
            flag_run = false     
            show_error_json(availability.errors.messages)
          end
        else
          availability.update_attributes(:is_block=> false)
          avail_ids << availability.id
        end
      else
        availability = @practitioner.availabilities.extra_unavails.where(["DATE(avail_date) = ? AND avail_time_start = CAST(? AS time) AND avail_time_end = CAST(? AS time)" , avail_params[:avail_date].to_date , avail_params[:avail_time_start] , avail_params[:avail_time_end] ]).first
        if availability.nil?
          availability = @practitioner.availabilities.new(avail_params)
          if availability.valid?
            availability.save
            avail_ids << availability.id
            # result = {flag: true , id: availability.id}
            # render :json => {availabilities: result}    
          else
            flag_run = false     
            show_error_json(availability.errors.messages)
          end 
        else
          availability.update_attributes(:is_block=> true)
          avail_ids << availability.id
        end
      end 
      
      avail_params[:avail_date] = avail_params[:avail_date].to_date + repeat_val
      end_val = end_val -1 
      
    end while ((end_val > 0) && flag_run == true)  
    
    if flag_run
      result = {flag: true , ids: avail_ids}
      render :json => result
    end
  end
  
  def random_key
    return rand(1000000)
  end
  
  def occurrence_parameters_same(avail , param_avail)
    param_avail[:repeat] = avail.repeat
    param_avail[:repeat_every] = avail.repeat_every
    param_avail[:ends_after] = avail.ends_after
    return param_avail 
  end
  
  def find_doctor
    @practitioner = User.find_by_id(params[:doctor_id])
  end
  
  def create_availability_manually(avail_params , business)
    avail  = @practitioner.availabilities.new(avail_params)
    if avail.valid?
      avail.unique_key = random_key
      avail.business =  business
      avail.save
      return avail.save
    else
      return false  
    end
  end
  

end
