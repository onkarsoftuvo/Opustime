 class ReportsController < ApplicationController
  respond_to :json
  before_filter :authorize
  before_action :find_company_by_sub_domain , :only =>[:index , :show_appointments_list , :export , :generate_pdf , :only_list_data]

  # authorize_resource :class => false

  # before_filter :load_permissions
  
  def index
    # authorize! :manage , :report
    result = {}
    result[:series] = []
      # Getting charts values for appointment
    if params[:type] == "appointment_type"
      result[:obj_names] = all_appointment_types
      all_appointment_types_ids.each do |appnt_type|
        unless appnt_type.first.nil?
          item = {}
          obj_name = appnt_type.second
          total_count = get_report_data_for_chart(appnt_type.first , params[:type] , params[:period], params[:start_date] , params[:end_date])
          item[:name] =   obj_name.to_s + " (#{total_count.sum})" 
          item[:data] = total_count
          result[:series] << item  
        end
      end 
    elsif params[:type] == "business"
      result[:obj_names] = all_businesses_names
      all_businesses_ids.each do |bs|
        unless bs.first.nil?
          item = {}
          obj_name = bs.second
          total_count = get_report_data_for_chart(bs.first , params[:type] , params[:period], params[:start_date] , params[:end_date])
          item[:name] = obj_name.to_s + " (#{total_count.sum})" 
          item[:data] = total_count
          result[:series] << item  
        end
      end
    elsif params[:type] == "doctor"
      result[:obj_names] = all_practitioners_names
      all_practitioners_ids.each do |doctor|
        unless doctor.first.nil?
          item = {}
          obj_name = doctor.second
          total_count = get_report_data_for_chart(doctor.first , params[:type] , params[:period], params[:start_date] , params[:end_date])
          item[:name] = obj_name.to_s + " (#{total_count.sum})" 
          item[:data] = total_count
          result[:series] << item  
        end
      end
    elsif params[:type] == "summary"
      result[:obj_names] = APPNT_SUMMARY.values
      APPNT_SUMMARY.keys.each  do |sm_key|
        item = {}
        obj_name = APPNT_SUMMARY[sm_key]
        total_count = get_report_data_summary_wise(sm_key , params[:period], params[:start_date], params[:end_date])
        item[:name] =   obj_name.to_s + " (#{total_count.sum})"
        item[:data] = total_count
        result[:series] << item
      end
    end

    year = (params[:start_date].to_date).strftime("%Y")
    st_date_y = Date.new(year.to_i , 1 , 1)
    end_date_y = (st_date_y + 1.year) - 1.day  
    result[:weekly_appointments] = weekly_appnts_count(st_date_y , end_date_y)
    result[:monthly_appointments] = monthly_appnts_count(st_date_y , end_date_y)
    result[:yearly_appointments] = yearly_appnts_count(st_date_y , end_date_y)
    render :json => result
  end 
  
  def show_appointments_list
    authorize! :manage , :report
    result = {}
    # Getting filters data 
    result[:practitioners] = all_available_practitioners
    result[:services] = all_available_services
    result[:locations] = all_available_locations

    # Getting listing values 
    result[:appointments_list_reports] = []
    loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
    service_params = params[:service].nil? ? nil : params[:service].split(",").map{|a| a.to_i}
    doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(",").map{|a| a.to_i}
    @appnts = get_filter_wise_appointments(loc_params, service_params , doctor_params, params[:st_date] , params[:end_date])
    @appointments = []
    if (params[:miss_appnt] == "true" || params[:miss_appnt] == true)
      @appnts.each do |apnt|
        @appointments << apnt if apnt.missed?
      end  
    else
      @appointments = @appnts
    end

    @appointments.each do |appnt|
      item = {}
      patient = appnt.patient
      item[:appnt_id] = appnt.try(:id)
      item[:patient_id] = patient.try(:id)
      item[:patient] = patient.full_name
      apnt_date = appnt.appnt_date.to_date.strftime("%A,%d %B %Y")
      apnt_start_time = appnt.appnt_time_start.strftime(" at %H:%M%p")
      item[:appnt_date] = (apnt_date + apnt_start_time).to_datetime
      item[:apnt_time] = appnt.appnt_time_start.strftime(" at %H:%M%p")
      item[:concession_type] = patient.concession.try(:name)
      item[:practitioner_name] = appnt.user.full_name_with_title
      item[:service_type] = appnt.appointment_type.try(:name)
      if appnt.patient.patient_contacts.present?
        item[:contact_no] = appnt.patient.patient_contacts.first.contact_no.phony_formatted(format: :international, spaces: '-')
      else
        item[:contact_no] = appnt.patient.patient_contacts.first.try(:contact_no)
      end
      # item[:contact_no] = appnt.patient.patient_contacts.first.try(:contact_no)
      item[:email] = appnt.patient.try(:email)
      item[:locations] = appnt.business.try(:name)
      result[:appointments_list_reports] << item
    end
    render :json => result
  end  

  def only_list_data
    # Getting listing values
    authorize! :manage , :report
    result = []
    loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
    service_params = params[:service].nil? ? nil : params[:service].split(",").map{|a| a.to_i}
    doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(",").map{|a| a.to_i}
    @appnts = get_filter_wise_appointments(loc_params, service_params , doctor_params, params[:st_date] , params[:end_date])
    @appointments = []
    if (params[:miss_appnt] == "true" || params[:miss_appnt] == true)
      @appnts.each do |apnt|
        @appointments << apnt if apnt.missed?
      end  
    else
      @appointments = @appnts
    end

    @appointments.each do |appnt| 
      item = {}
      patient = appnt.patient
      item[:appnt_id] = appnt.try(:id)
      item[:patient_id] = patient.try(:id)
      item[:patient] = patient.full_name
      apnt_date = appnt.appnt_date.to_date.strftime("%A,%d %B %Y")
      apnt_start_time = appnt.appnt_time_start.strftime(" at %H:%M%p")
      item[:appnt_date] = apnt_date + apnt_start_time

      item[:concession_type] = patient.concession.try(:name)
      item[:practitioner_name] = appnt.user.full_name_with_title
      item[:service_type] = appnt.appointment_type.try(:name)
      item[:contact_no] = appnt.patient.patient_contacts.first.try(:contact_no)
      item[:email] = appnt.patient.try(:email)
      item[:locations] = appnt.business.try(:name)
      result << item
    end
    render :json => result


  end

  def export
    begin
      authorize! :manage , :report
      loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
      service_params = params[:service].nil? ? nil : params[:service].split(",").map{|a| a.to_i}
      doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(",").map{|a| a.to_i}

      @appnts = get_filter_wise_appointments(loc_params, service_params , doctor_params, params[:st_date] , params[:end_date])
      @appointments = []
      if (params[:miss_appnt] == "true" || params[:miss_appnt] == true)
        @appnts.each do |apnt|
          @appointments << apnt if apnt.missed?
        end
      else
        @appointments = @appnts
      end

      respond_to do |format|
        format.html
        format.csv { render text: @appointments.to_csv , status: 200 }
      end

    rescue Exception => e
      render :text => e.message  
    end

  end

  def generate_pdf
    authorize! :manage , :report
    @result = []
    loc_params =  params[:loc].nil? ? nil : params[:loc].split(",").map{|a| a.to_i}
    service_params = params[:service].nil? ? nil : params[:service].split(",").map{|a| a.to_i}
    doctor_params =  params[:doctor].nil? ? nil : params[:doctor].split(",").map{|a| a.to_i}

    @appnts = get_filter_wise_appointments(loc_params, service_params , doctor_params, params[:st_date] , params[:end_date])
    @appointments = []
    if (params[:miss_appnt] == "true" || params[:miss_appnt] == true)
      @appnts.each do |apnt|
        @appointments << apnt if apnt.missed?
      end  
    else
      @appointments = @appnts
    end

    @appointments.each do |appnt|
      item = {}
      patient = appnt.patient
      item[:appnt_id] = appnt.try(:id)
      item[:patient] = patient.full_name
      apnt_date = appnt.appnt_date.to_date.strftime("%A,%d %B %Y")
      apnt_start_time = appnt.appnt_time_start.strftime(" at %H:%M%p")
      item[:appnt_date] = apnt_date + apnt_start_time

      item[:concession_type] = patient.concession.try(:name)
      item[:practitioner_name] = appnt.user.full_name_with_title
      item[:service_type] = appnt.appointment_type.try(:name)
      item[:contact_no] = appnt.patient.patient_contacts.first.try(:contact_no)
      item[:email] = appnt.patient.try(:email)
      item[:locations] = appnt.business.try(:name)
      @result << item
    end
    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => "pdf_name.pdf" , 
               :layout => '/layouts/pdf.html.erb' ,
               :disposition => 'inline' ,
               :template    => "/reports/generate_pdf",
               :show_as_html => params[:debug].present? ,
               :footer=> { right: '[page] of [topage]' }
      end
    end

  end
  
  
  
  private 
  
  # appointment type infos 
  
  def avail_appointment_types
    @company.appointment_types.map(&:name)
  end
  
  def all_appointment_types
    (avail_appointment_types).uniq
  end
  
  def all_appointment_types_ids
    @company.appointment_types.pluck("id , name ")
  end 
  
  # business info 
  def all_businesses_ids
    @company.businesses.pluck("id , name")
  end
  
  def all_businesses_names
    @company.businesses.map(&:name)
  end
  
  # practitioners info 
  def all_practitioners_names
    result = []
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      doctors = @company.users.doctors.where(['users.id = ?' , current_user.id])
    else
      doctors = @company.users.doctors
    end

    doctors.each do |dc|
      result << dc.full_name_with_title
    end
    return result 
  end
  
  def all_practitioners_ids
    result = []
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      doctors = @company.users.doctors.where(['users.id = ?' , current_user.id])
    else
      doctors = @company.users.doctors
    end

    doctors.each do |dc|
      item = []
      item << dc.id
      item << dc.full_name_with_title
      result << item
    end
    return result 
  end
  
  # counting for objects
  def get_report_data_for_chart(obj_id , obj_type , period , start_date , end_date)
    result = []
    if period == "week"
      (start_date.to_date .. end_date.to_date).each do |dt|
        result <<  total_appointments_count(obj_id , dt , obj_type)   
      end
    elsif period == "month"
      (start_date.to_date .. end_date.to_date).each do |dt|
        result <<  total_appointments_count(obj_id , dt , obj_type)   
      end   
    elsif period == "year"
      count_month = 1
      result = []
      st_date = start_date.to_date
      while count_month <= 12
        result <<  total_appointments_count_monthly(obj_id , obj_type, st_date , (st_date + 1.month - 1.day) )
        count_month = count_month + 1
        st_date = st_date + 1.month
      end
    end
    return result
  end

  def total_appointments_count(id , dt , flag)
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      case flag
        when 'appointment_type'
          @company.appointments.active_appointment.joins(:appointment_type).where(["user_id = ? AND appointment_types.id = ? AND DATE(appnt_date) = ? ", current_user.id , id , dt.to_date]).count
        when 'business'
          @company.appointments.active_appointment.joins(:business).where(["user_id = ? AND businesses.id = ? AND DATE(appnt_date) = ? ", current_user.id , id , dt.to_date]).count
        when 'doctor'
          @company.appointments.active_appointment.joins(:user).where(["user_id = ? AND users.id = ? AND DATE(appnt_date) = ? ", current_user.id , id , dt.to_date]).count
      end
    else
      case flag
        when 'appointment_type'
          @company.appointments.active_appointment.joins(:appointment_type).where(["appointment_types.id = ? AND DATE(appnt_date) = ? ", id , dt.to_date]).count
        when 'business'
          @company.appointments.active_appointment.joins(:business).where(["businesses.id = ? AND DATE(appnt_date) = ? ", id , dt.to_date]).count
        when 'doctor'
          @company.appointments.active_appointment.joins(:user).where(["users.id = ? AND DATE(appnt_date) = ? ", id , dt.to_date]).count
      end
    end

  end
  
  def total_appointments_count_monthly(id , obj_type, st_date , end_date )
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      case obj_type
        when 'appointment_type'
          @company.appointments.active_appointment.joins(:appointment_type).where(["user_id = ? AND appointment_types.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", current_user.id , id , st_date , end_date]).count
        when 'business'
          @company.appointments.active_appointment.joins(:business).where(["user_id = ? AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", current_user.id , id , st_date , end_date]).count
        when 'doctor'
          @company.appointments.active_appointment.joins(:user).where(["user_id = ? AND users.id = ? AND users.acc_active = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", current_user.id , id , true , st_date , end_date]).count
      end
    else
      case obj_type
        when 'appointment_type'
          @company.appointments.active_appointment.joins(:appointment_type).where(["appointment_types.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", id , st_date , end_date]).count
        when 'business'
          @company.appointments.active_appointment.joins(:business).where(["businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", id , st_date , end_date]).count
        when 'doctor'
          @company.appointments.active_appointment.joins(:user).where(["users.id = ? AND users.acc_active = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", id , true , st_date , end_date]).count
      end
    end

  end
  
  def weekly_appnts_count(st_date , end_date)
    (@company.appointments.active_appointment.where(["Date(appnt_date) >= ? AND Date(appnt_date) <= ?" , st_date.to_date , end_date.to_date ]).count)/52
  end
  
  def monthly_appnts_count(st_date , end_date)
    (@company.appointments.active_appointment.where(["Date(appnt_date) >= ? AND Date(appnt_date) <= ?" , st_date.to_date , end_date.to_date ]).count)/12
  end

  def yearly_appnts_count(st_date , end_date)
    (@company.appointments.active_appointment.where(["Date(appnt_date) >= ? AND Date(appnt_date) <= ?" , st_date.to_date , end_date.to_date ]).count)
  end

  def all_available_practitioners
    result = []
    @company.users.doctors.each do |doctor|
      item = {}
      item[:id] = doctor.id
      item[:name] = doctor.full_name_with_title
      result << item 
    end
    return result
  end

  def all_available_locations
    result = []
    @company.businesses.each do |business|
      item = {}
      item[:id] = business.id
      item[:name] = business.name
      result << item 
    end
    return result
  end

  def all_available_services
    result = []
    @company.appointment_types.each do |service|
      item = {}
      item[:id] = service.id
      item[:name] = service.name
      result << item 
    end
    return result
  end

  def get_filter_wise_appointments(loc, service , doctor , st_date , end_date)
    result = []
    unless st_date.nil? && end_date.nil?
      st_date = st_date.try(:to_date)
      end_date = end_date.try(:to_date)
      if loc.nil? && service.nil? && doctor.nil?  
        result = @company.appointments.active_appointment.where(["DATE(appnt_date) >= ? AND DATE(appnt_date) <= ? " , st_date.to_date , end_date.to_date])
      elsif !(loc.nil?) && service.nil? && doctor.nil?
        result = @company.appointments.joins(:business).where(["businesses.id IN (?) ", loc]).active_appointment.where(["DATE(appnt_date) >= ? AND DATE(appnt_date) <= ? " , st_date.to_date , end_date.to_date])
      elsif (loc.nil?) && !(service.nil?) && doctor.nil?    
        result = @company.appointments.joins(:appointment_type).where(["appointment_types.id IN (?) ", service]).active_appointment.where(["DATE(appnt_date) >= ? AND DATE(appnt_date) <= ? " , st_date.to_date , end_date.to_date])
      elsif (loc.nil?) && (service.nil?) && !(doctor.nil?)
        result = @company.appointments.joins(:user).where(["users.id IN (?) ", doctor]).active_appointment.where(["DATE(appnt_date) >= ? AND DATE(appnt_date) <= ? " , st_date.to_date , end_date.to_date])  
      elsif !(loc.nil?) && !(service.nil?) && doctor.nil?
        result = @company.appointments.joins(:business , :appointment_type).where(["businesses.id IN (?) AND appointment_types.id IN (?)", loc , service]).active_appointment.where(["DATE(appnt_date) >= ? AND DATE(appnt_date) <= ? " , st_date.to_date , end_date.to_date])
      elsif !(loc.nil?) && (service.nil?) && !(doctor.nil?)
        result = @company.appointments.joins(:business , :user).where(["businesses.id IN (?) AND users.id IN (?)", loc , doctor]).active_appointment.where(["DATE(appnt_date) >= ? AND DATE(appnt_date) <= ? " , st_date.to_date , end_date.to_date])
      elsif (loc.nil?) && !(service.nil?) && !(doctor.nil?)
        result = @company.appointments.joins(:appointment_type , :user).where(["appointment_types.id IN (?) AND users.id IN (?)", service , doctor]).active_appointment.where(["DATE(appnt_date) >= ? AND DATE(appnt_date) <= ? " , st_date.to_date , end_date.to_date])
      elsif !(loc.nil?) && !(service.nil?) && !(doctor.nil?)
        result = @company.appointments.joins(:business , :appointment_type , :user).where(["appointment_types.id IN (?) AND users.id IN (?) AND businesses.id IN (?)", service , doctor , loc]).active_appointment.where(["DATE(appnt_date) >= ? AND DATE(appnt_date) <= ? " , st_date.to_date , end_date.to_date])
      end
      return result
    else
      if loc.nil? && service.nil? && doctor.nil?
        result = @company.appointments.active_appointment
      elsif !(loc.nil?) && service.nil? && doctor.nil?
        result = @company.appointments.joins(:business).where(["businesses.id IN (?) ", loc])
      elsif (loc.nil?) && !(service.nil?) && doctor.nil?    
        result = @company.appointments.joins(:appointment_type).where(["appointment_types.id IN (?) ", service]).active_appointment
      elsif (loc.nil?) && (service.nil?) && !(doctor.nil?)
        result = @company.appointments.joins(:user).where(["users.id IN (?) ", doctor]).active_appointment
      elsif !(loc.nil?) && !(service.nil?) && doctor.nil?
        result = @company.appointments.joins(:business , :appointment_type).where(["businesses.id IN (?) AND appointment_types.id IN (?)", loc , service]).active_appointment
      elsif !(loc.nil?) && (service.nil?) && !(doctor.nil?)
        result = @company.appointments.joins(:business , :user).where(["businesses.id IN (?) AND users.id IN (?)", loc , doctor]).active_appointment
      elsif (loc.nil?) && !(service.nil?) && !(doctor.nil?)
        result = @company.appointments.joins(:appointment_type , :user).where(["appointment_types.id IN (?) AND users.id IN (?)", service , doctor]).active_appointment
      elsif !(loc.nil?) && !(service.nil?) && !(doctor.nil?)
        result = @company.appointments.joins(:business , :appointment_type , :user).where(["appointment_types.id IN (?) AND users.id IN (?) AND businesses.id IN (?)", service , doctor , loc]).active_appointment
      end  
      return result.order('DATE(appnt_date) asc')
    end
  end  

  def summary_wise_appointment_types
    APPNT_SUMMARY    
  end

  def get_report_data_summary_wise(sm_key , period , start_date , end_date)
    result = []
    if period == "week"
      (start_date.to_date .. end_date.to_date).each do |dt|
        result <<  summary_wise_appointments_count(sm_key , dt)   
      end 
    elsif period == "month"
      (start_date.to_date .. end_date.to_date).each do |dt|
        result <<  summary_wise_appointments_count(sm_key , dt)   
      end
    elsif period == "year"
      count_month = 1
      result = []
      st_date = start_date.to_date
      while count_month <= 12
        result <<  summary_wise_appointments_count_monthly(sm_key , st_date , (st_date + 1.month - 1.day) )
        count_month = count_month + 1
        st_date = st_date + 1.month
      end
    end
    return result

  end

  def summary_wise_appointments_count(sm_key , dt)
    count = 0
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      count = @company.appointments.where(["user_id = ? AND appointments.summary = ? AND appointments.appnt_date = ?" , current_user.id , APPNT_SUMMARY[sm_key] , dt]).uniq.count
    else
      count = @company.appointments.where(["appointments.summary = ? AND appointments.appnt_date = ?" , APPNT_SUMMARY[sm_key] , dt]).uniq.count
    end

    return count  
  end

  def summary_wise_appointments_count_monthly(sm_key , st_date , end_date )
    count = 0
    if (current_user.is_doctor && current_user.user_role.try(:name).eql?(ROLE[2]))
      count = @company.appointments.where(["user_id = ? AND appointments.summary = ? AND appointments.appnt_date >= ? AND appointments.appnt_date <= ? " , current_user.id , APPNT_SUMMARY[sm_key] , st_date , end_date]).uniq.count
    else
      count = @company.appointments.where(["appointments.summary = ? AND appointments.appnt_date >= ? AND appointments.appnt_date <= ? " , APPNT_SUMMARY[sm_key] , st_date , end_date]).uniq.count
    end

    return count  
  end
   
end