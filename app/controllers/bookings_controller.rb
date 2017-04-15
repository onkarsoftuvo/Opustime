class BookingsController < ApplicationController
  layout "application_booking"
  respond_to :json

  before_action :find_company, :only => [:available_services, :avail_business_locations, :service_wise_practitioners,
                                         :online_booking_info, :practitioner_availability_for_a_month, :practitioner_availability_on_specific_date, :avail_color_option, :get_business_info]

  before_action :find_company_by_sub_domain, :only => [:available_services, :avail_business_locations, :service_wise_practitioners,
                                                     :online_booking_info, :practitioner_availability_for_a_month, :practitioner_availability_on_specific_date, :avail_color_option, :get_business_info]

  # using only for postman to test API. Remove later  
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }
  skip_before_filter :verify_authenticity_token, :only => [:get_data]
  def booking_show_page

    if params[:signed_request].present?
      data = parse_signed_request(CONFIG[:FB_SECRET], params[:signed_request])
      result = {}
      if data.class == Hash
        page_id = data["page"]["id"]
        fb_page = FacebookPage.find_by_page_id(page_id)
        company = fb_page.company

        unless company.nil?
          company_name = company.company_name.to_s.downcase.gsub(' ','-')
          # url = request.original_url
          url = "https://#{company_name}.opustime.com/booking"
          logger.info "Processing the request... url is ...... #{url}"
          # url = url.gsub(/http:/, "https:")
          redirect_to url 
        end
      end

    end
  end

  def online_booking_info
    result = {}
    online_setting = @company.online_booking
    account = @company.account
    result[:logo] = online_setting.logo
    result[:company_name] = account.company_name
    result[:time_sel_info] =online_setting.try(:time_sel_info)
    result[:hide_patient_address] = online_setting.req_patient_addr
    result[:term_and_condition] = (online_setting.terms.blank? ? nil : online_setting.terms)
    result[:show_dob] = online_setting.show_dob
    render :json => result
  end

  def avail_business_locations
    locations = @company.businesses.where(online_booking: true)
    result = []
    locations.each do |loc|
      item = {}
      item[:id] = loc.id
      item[:name] = loc.name
      item[:address] = loc.address
      item[:city] = loc.city
      item[:state] = loc.state
      item[:pin_code] = loc.pin_code
      item[:country] = loc.country
      item[:full_address] = loc.full_address
      item[:reg_name] = loc.reg_name
      item[:reg_number] = loc.reg_number
      result << item
    end
    online_setting = @company.online_booking
    render :json => {:locations => result}
  end

  def avail_color_option
    result = {}
    color_opt = @company.account
    result[:theme_name] = color_opt.theme_name
    #online_setting = @company.online_booking
    render :json => result
  end

  def get_business_info
    result = {}
    patient = @company.patients.where(first_name: params[:first_name], last_name: params[:last_name], email: params[:email]).first
    if patient.nil?
      head_loc = @company.businesses.head.first
      result[:c_code] = head_loc.try(:country)
      result[:state] = head_loc.try(:state)
    else
      last_visit_loc = patient.appointments.last.try(:business)
      last_visit_loc = patient.invoices.last.try(:business) if last_visit_loc.nil?
      unless last_visit_loc.nil?
        result[:c_code] = last_visit_loc.try(:country)
        result[:state] = last_visit_loc.try(:state)
      else
        head_loc = @company.businesses.head.first
        result[:c_code] = head_loc.try(:country)
        result[:state] = head_loc.try(:state)
      end
    end
    render :json => result

  end

  def available_services
    result = []
    unless @company.nil?
      doctor_ids = @company.users.doctors.joins(:practitioner_avails => [:days]).where(["business_id = ? AND days.is_selected = ?", params[:business_id], true]).map(&:id).uniq
      avail_services = @company.appointment_types.joins(:users).where(["users.id IN (?) AND appointment_types.allow_online = ? ", doctor_ids, true]).uniq
      online_setting = @company.online_booking
      avail_services.each do |service|
        item = {}
        item[:id] = service.id
        item[:service_name] = service.name
        item[:category] = service.category
        item[:description] = service.description
        item[:duration_time] = service.duration_time
        rate = 0
        if service.billable_items.length > 0
          service.billable_items.each do |bill_item|
            rate = rate + bill_item.price.to_i
          end
        end
        item[:show_price] = online_setting.show_price
        item[:service_rate] = rate
        item[:hide_end_time] = online_setting.hide_end_time
        result << item
      end
    end
    render :json => result

  end

  def service_wise_practitioners
    service = AppointmentType.find_by_id(params[:service_id])
    doctor_ids = @company.users.doctors.joins(:practitioner_avails => [:days]).where(["business_id = ? AND days.is_selected = ?", params[:business_id], true]).map(&:id).uniq
    result = []
    doctors = service.users.joins(:practi_info).where(["practi_infos.is_online = ? AND users.id IN (?)", true, doctor_ids])
    unless service.nil?
      doctors.each do |doctor|
        item = {}
        item[:id] = doctor.id
        item[:name] = doctor.full_name_with_title
        item[:designation] = doctor.practi_info.try(:designation)
        item[:desc] = doctor.practi_info.try(:desc)
        result << item
      end
    end
    render :json => {:practitioner_avails => result}
  end

  def practitioner_availability_for_a_month
    result = []
    doctor = @company.users.find_by_id(params[:id])
    appointment_type = @company.appointment_types.find_by_id(params[:appointment_type])
    unless params[:y].nil? && params[:m].nil?
      first_date = Date.civil(params[:y].to_i, params[:m].to_i, 1)
      last_date = first_date + 1.month - 1.day
      online_time = @company.online_booking.online_time_period_for_appnt
      (first_date..last_date).each do |dt|
        if dt >= online_time.to_date
          item = {}
          unless doctor.nil? && appointment_type.nil?
            doctor_avail = doctor.practitioner_avails.where(business_id: params[:b_id]).first
            duration_time = appointment_type.duration_time
            days = doctor_avail.days
            days.each do |day|
              if dt.strftime("%A").casecmp(day.day_name) == 0
                if day.is_selected == true
                  time_slots = change_time_in_slots(day.start_hr, day.start_min, day.end_hr, day.end_min) #change_time_into_slots(day.start_hr , day.start_min , day.end_hr , day.end_min , duration_time)
                  day_breaks = day.practitioner_breaks
                  day_breaks.each do |bk|
                    bk_item = []
                    break_st_time = change_time_into_decimal_number(bk.start_hr, bk.start_min)
                    bk_item << convert_decimal_number_into_time(break_st_time)
                    break_end_time = change_time_into_decimal_number(bk.end_hr, bk.end_min)
                    bk_item << convert_decimal_number_into_time(break_end_time)
                    time_slots = break_time_slots_when_break_exists(time_slots, bk_item) #remove_slots_in_which_break_slot_exist(time_slots , bk_item)
                  end

                  # if any one-off availability exists and does not include in time slots then include that one  
                  one_off_avails = doctor.availabilities.extra_avails.where(["DATE(avail_date) = ? ", dt])
                  avail_time_slots = []
                  one_off_avails.each do |avail|
                    avail_time_slots = avail_time_slots + change_time_in_slots(avail.avail_time_start.strftime("%H"), avail.avail_time_start.strftime("%M"), avail.avail_time_end.strftime("%H"), avail.avail_time_end.strftime("%M"))
                  end
                  avail_time_slots.each do |avail_slot|
                    time_slots = merge_time_slots(avail_slot, time_slots)
                  end

                  # if any un-availability exists   
                  unavails_periods = doctor.availabilities.extra_unavails.where(["DATE(avail_date) = ? ", dt])
                  unavail_time_slots = []
                  unavails_periods.each do |unavail|
                    unavail_time_slots = unavail_time_slots + change_time_in_slots(unavail.avail_time_start.strftime("%H"), unavail.avail_time_start.strftime("%M"), unavail.avail_time_end.strftime("%H"), unavail.avail_time_end.strftime("%M"))
                  end
                  unavail_time_slots.each do |unavail_slot|
                    time_slots = break_time_slots_when_break_exists(time_slots, unavail_slot)
                  end

                  # checking is there any appointment on the same day
                  appnts = doctor.appointments.joins(:business).where(["businesses.id = ? AND DATE(appnt_date) = ? ", params[:b_id], dt]).active_appointment.uniq
                  appnt_time_slots = []
                  appnts.each do |appnt|
                    appnt_time_slots = appnt_time_slots + change_time_in_slots(appnt.appnt_time_start.strftime("%H"), appnt.appnt_time_start.strftime("%M"), appnt.appnt_time_end.strftime("%H"), appnt.appnt_time_end.strftime("%M"))
                  end
                  appnt_time_slots = remove_appnt_slot_out_of_time_slot(time_slots, appnt_time_slots)
                  appnt_time_slots.each do |appnt_slot|
                    time_slots = break_time_slots_when_break_exists(time_slots, appnt_slot)
                  end

                  time_slot_with_duration = []
                  time_slots.each do |slot|
                    start_time = slot[0].split(":")
                    end_time = slot[1].split(":")
                    time_slot_with_duration = time_slot_with_duration + change_time_into_slots(start_time[0], start_time[1], end_time[0], end_time[1], duration_time)
                  end

                  item[:date] = dt
                  item[:time_slots] = slots_classification(time_slot_with_duration)
                  result << item
                else
                  item = {}
                  item[:date] = dt
                  item_day = {}
                  item_day[:morning_flag] = false
                  item_day[:afternoon_flag] = false
                  item_day[:evening_flag] = false
                  item[:time_slots] = item_day
                  result << item
                end

              end
            end

          end
        else
          item = {}
          item[:date] = dt
          item_day = {}
          item_day[:morning_flag] = false
          item_day[:afternoon_flag] = false
          item_day[:evening_flag] = false
          item[:time_slots] = item_day
          result << item
        end

      end

    end

    render :json => {availability: result}
  end

  def practitioner_availability_on_specific_date
    result = {}
    doctor = @company.users.doctors.find_by_id(params[:id])
    appointment_type = @company.appointment_types.find_by_id(params[:appointment_type])
    unless params[:y].nil? && params[:m].nil? & params[:d].nil?
      dt = Date.new(params[:y].to_i, params[:m].to_i, params[:d].to_i)
      if dt >= Date.today
        item = {}
        unless doctor.nil? && appointment_type.nil?
          doctor_avail = doctor.practitioner_avails.where(business_id: params[:b_id]).first
          duration_time = appointment_type.duration_time
          days = doctor_avail.days
          days.each do |day|
            if dt.strftime("%A").casecmp(day.day_name) == 0
              if day.is_selected == true
                time_slots = change_time_in_slots(day.start_hr, day.start_min, day.end_hr, day.end_min) #change_time_into_slots(day.start_hr , day.start_min , day.end_hr , day.end_min , duration_time)
                day_breaks = day.practitioner_breaks
                temp = []
                item[:time_slots_before_merge] = time_slots
                day_breaks.each do |bk|
                  bk_item = []
                  break_st_time = change_time_into_decimal_number(bk.start_hr, bk.start_min)
                  bk_item << convert_decimal_number_into_time(break_st_time)
                  break_end_time = change_time_into_decimal_number(bk.end_hr, bk.end_min)
                  bk_item << convert_decimal_number_into_time(break_end_time)
                  time_slots = break_time_slots_when_break_exists(time_slots, bk_item) #remove_slots_in_which_break_slot_exist(time_slots , bk_item)
                  temp << bk_item
                end
                item[:breaks_slots] = temp

                # if any one-off availability exists and does not include in time slots then include that one
                one_off_avails = doctor.availabilities.extra_avails.joins(:business).where(["businesses.id = ? and DATE(avail_date) = ? ", params[:b_id], dt])
                avail_time_slots = []
                one_off_avails.each do |avail|
                  avail_time_slots = avail_time_slots + change_time_in_slots(avail.avail_time_start.strftime("%H"), avail.avail_time_start.strftime("%M"), avail.avail_time_end.strftime("%H"), avail.avail_time_end.strftime("%M"))
                end
                avail_time_slots.each do |avail_slot|
                  time_slots = merge_time_slots(avail_slot, time_slots)
                end
                item[:avail_time_slots] = avail_time_slots

                # if any un-availability exists
                unavails_periods = doctor.availabilities.extra_unavails.joins(:business).where(["businesses.id = ? and DATE(avail_date) = ? ", params[:b_id], dt])
                unavail_time_slots = []
                unavails_periods.each do |unavail|
                  unavail_time_slots = unavail_time_slots + change_time_in_slots(unavail.avail_time_start.strftime("%H"), unavail.avail_time_start.strftime("%M"), unavail.avail_time_end.strftime("%H"), unavail.avail_time_end.strftime("%M"))
                end
                unavail_time_slots.each do |unavail_slot|
                  time_slots = break_time_slots_when_break_exists(time_slots, unavail_slot)
                end

                item[:unavail_time_slots] = unavail_time_slots

                # checking is there any appointment on the same day
                appnts = doctor.appointments.joins(:business).where("businesses.id = ? AND DATE(appnt_date) = ? AND cancellation_time IS ?  AND status = ?", params[:b_id], dt, nil, 1).uniq
                appnt_time_slots = []
                appnts.each do |appnt|
                  appnt_time_slots = appnt_time_slots + change_time_in_slots(appnt.appnt_time_start.strftime("%H"), appnt.appnt_time_start.strftime("%M"), appnt.appnt_time_end.strftime("%H"), appnt.appnt_time_end.strftime("%M"))
                end


                #  Checking setting module for  remove the time slots

                item[:appnt_time_slots] = appnt_time_slots
                appnt_time_slots = remove_appnt_slot_out_of_time_slot(time_slots, appnt_time_slots)
                appnt_time_slots.each do |appnt_slot|
                  time_slots = break_time_slots_when_break_exists(time_slots, appnt_slot)
                end



                # removed passed slots
                online_time_setting = @company.online_booking.online_time_period_for_appnt
                online_time = Date.new(params['y'].to_i , params['m'].to_i , params['d'].to_i )
                item[:time_slots_already_appnt] = appnt_time_slots
                passed_time_slots = []
                if online_time.to_date == Date.today
                  passed_time_slots = passed_time_slots + change_time_in_slots(0, 0, online_time_setting.strftime("%H"), online_time_setting.strftime("%M"))
                  print passed_time_slots.first.last
                  check_past_time = passed_time_slots.first.last.split(':')
                  if check_past_time.first.to_i < day.start_hr.to_i
                    passed_time_slots.first[1] = "#{day.start_hr}:#{day.start_min}"
                  end
                  last_passed_slot = passed_time_slots.first[1].split(':')
                  # if last_passed_slot.last
                  passed_time_slots.first[1] = "#{passed_time_slots.first[1].split(':').first}:#{last_passed_slot[1].to_i.round(-1).to_s}"
                  time_slots = clear_passed_slot(time_slots, passed_time_slots,day.start_hr, day.start_min)

                end

                time_slots = exist_in_slots(time_slots, duration_time)

                item[:time_slots_after_merge] = time_slots
                time_slot_with_duration = []
                time_slots.each do |slot|
                  start_time = slot[0].split(":")
                  end_time = slot[1].split(":")
                  time_slot_with_duration = time_slot_with_duration + change_time_into_slots(start_time[0], start_time[1], end_time[0], end_time[1], duration_time)
                end
                item[:date] = dt
                item[:time_slots] = slots_classification(time_slot_with_duration, true)
                result = item
              else
                item = {}
                item[:date] = dt
                item_day = {}
                item_day[:morning] = []
                item_day[:morning_flag] = false
                item_day[:afternoon_flag] = false
                item_day[:evening_flag] = false
                item_day[:afternoon] = []
                item_day[:evening] = []
                item[:time_slots] = item_day
                result = item
              end

            end
          end

        end
      else
        item = {}
        item[:date] = dt
        item_day = {}
        item_day[:morning] = []
        item_day[:morning_flag] = false
        item_day[:afternoon_flag] = false
        item_day[:evening_flag] = false
        item_day[:afternoon] = []
        item_day[:evening] = []
        item[:time_slots] = item_day
        result = item
      end

      # end

    end

    result[:hide_end_time] = @company.online_booking.try(:hide_end_time)
    render :json => result
  end

  def exist_in_slots(slots, dur)
    item = []
    slots.each do |slot|
      slot_time = ((Time.parse(slot.last) - Time.parse(slot.first)) / 1.minute).round
      if slot_time >= dur.to_i
        item << slot
      end
    end
    return item
  end

  def get_patient_detail_by_token
    patient = params[:patient_token].nil? ? params[:patient_token] : Patient.find_by_token(params[:patient_token].to_s)
    result = {}
    unless patient.nil?
      result[:id] = patient.id
      result[:first_name] = patient.first_name
      result[:last_name] = patient.last_name
      dob = patient.dob.try(:to_date)
      unless dob.nil?
        result[:birthDay] = dob.to_date.strftime("%d")
        result[:birthMonth] = dob.to_date.strftime("%m")
        result[:birthYear] = dob.to_date.strftime("%Y")
      else
        result[:birthDay] = result[:birthMonth] = result[:birthYear] = nil
      end
      result[:email] = patient.email
      patient_contact = patient.patient_contacts.last
      unless patient_contact.nil?
        result[:contact_no] = patient_contact.contact_no
        result[:contact_type] = patient_contact.contact_type
      else
        patient[:contact_no] = nil
        patient[:contact_type] = nil
      end
      result[:address] = patient.address
      result[:city] = patient.city
      result[:country] = patient.country
      result[:state] = patient.state
      result[:postal_code] = patient.postal_code
      result[:remember_me] = true
    end
    render :json => {:patient_detail => result }
  end

  def generate_ical_event
    @appnt = Appointment.find(params[:id])

    respond_to do |format|
      format.html
      format.ics do
        calendar = Icalendar::Calendar.new
        calendar.add_event(@appnt.to_ics)
        calendar.publish
        render :text => calendar.to_ical
      end
    end

  end

  def email_to_others
    @appnt = Appointment.find(params[:id])
    email_send_to = params[:other_email]
    AppointmentBookingWorker.perform_async(@appnt.id, "patient", email_send_to)
    render :json => {flag: true}
  end

  # insert appointment event on google calendar
  def verify_calendar_auth
    if session[:appnt_id].present?
      appont = Appointment.where(["status = ? AND id = ?", true, session[:appnt_id]]).first
      unless appont.nil?
        auth = request.env["omniauth.auth"]
        client = Google::APIClient.new({:application_name => "OpusTime",
                                        :application_version => "1.0"})

        token = auth["credentials"]["token"]

        appnt_date = appont.appnt_date
        dt_y = appnt_date.strftime("%Y").to_i
        dt_m = appnt_date.strftime("%m").to_i
        dt_dt = appnt_date.strftime("%dT").to_i

        st_hr = appont.appnt_time_start.strftime("%H").to_i
        st_min = appont.appnt_time_start.strftime("%M").to_i
        st_sec = appont.appnt_time_start.strftime("%S").to_i

        end_hr = appont.appnt_time_end.strftime("%H").to_i
        end_min = appont.appnt_time_end.strftime("%M").to_i
        end_sec = appont.appnt_time_end.strftime("%S").to_i


        start_appnt_date = DateTime.new(dt_y, dt_m, dt_dt, st_hr, st_min, st_sec)
        end_appnt_date = DateTime.new(dt_y, dt_m, dt_dt, end_hr, end_min, end_sec)

        @event = {
            'summary' => appont.name_with_category,
            'description' => "you are seeing by #{appont.user.full_name_with_title}",
            'location' => "#{appont.business.name}",
            'start' => {'dateTime' => start_appnt_date},
            'end' => {'dateTime' => end_appnt_date}
        }
        service = client.discovered_api('calendar', 'v3')
        client.authorization.access_token = token
        # auth[:extra]["id_info"]["email"]
        @set_event = client.execute(:api_method => service.events.insert,
                                    :parameters => {'calendarId' => auth[:extra]["id_info"]["email"]},
                                    :body => JSON.dump(@event),
                                    :headers => {'Content-Type' => 'application/json'})
        if @set_event.status == 200
          redirect_to "http://calendar.google.com/calendar/render/"
        else
          appnt = Appointment.new
          appnt.errors.add(:domain, "not found !")
          show_error_json(appnt.errors.messages)
        end
      else
        appnt = Appointment.new
        appnt.errors.add(:appointment, "does not exists")
        show_error_json(appnt.errors.messages)
      end
    else
      appnt = Appointment.new
      appnt.errors.add(:appointment, "does not exists")
      show_error_json(appnt.errors.messages)
    end
  end

  def google_calendar
    session[:appnt_id] = params[:id]
    redirect_to "/auth/google_oauth2"
  end

  def save_path
    if params[:current_path].present?
      decoded = params[:current_path]
      decoded_url = Base64.decode64(decoded)
      session[:current_path] = decoded_url
      render :json=>{:flag =>true}
    else
      render :json=>{:flag => false}
    end
  end

  def get_data
    facebook_detail = FacebookDetail.find_by(params[:fb_id]) rescue nil?
    item = { has_record: false}
    unless facebook_detail.nil?
      item[:fb_detail_id] = facebook_detail.id
      item[:first_name] = facebook_detail.first_name
      item[:last_name] = facebook_detail.last_name
      item[:day] = (facebook_detail.dob.nil? ? (facebook_detail.dob) : (facebook_detail.dob.strftime("%e")).strip)
      item[:month] = (facebook_detail.dob.nil? ? (facebook_detail.dob) : (facebook_detail.dob.strftime("%m")).strip)
      item[:year] = (facebook_detail.dob.nil? ? (facebook_detail.dob) : (facebook_detail.dob.strftime("%Y")).strip)
      item[:email] = facebook_detail.email
      item[:address] = facebook_detail.try(:address)
      item[:city] = facebook_detail.try(:city)
      item[:profile_pic] = facebook_detail.try(:logo)
      item[:fb_url] = facebook_detail.try(:fb_url)
      item[:gender] = facebook_detail.try(:gender)
      item[:has_record] = true
    end
    session[:current_path] = nil
    render :json=> item and return
  end

  def remove_fb_detail
    facebook_detail = FacebookDetail.find_by(params[:id]) rescue nil? unless params[:id].nil?
    unless facebook_detail.nil?
      facebook_detail.destroy
      render :json => {:flag => true}
    else
      render :json => {:flag => false}
    end
  end


  def facebook_login
    profile_img_logo , patient = Patient.koala(request.env['omniauth.auth']['credentials'])

    unless session[:current_path].nil?
      current_path = session[:current_path]
      host_name = URI.parse(current_path).host.sub(/^www\./, '')
      # comp_id = current_path.split('=')[1].split('#')[0]
      splited_domain = host_name.split('.')
      domain_name = splited_domain.length <= 2 ? '' : splited_domain[0]
      company = Company.where(['lower(company_name) = ?' , domain_name.downcase ]).first
      loc_name = patient["location"]["name"] rescue nil
      city = patient["hometown"]["name"] rescue nil
      profile_pic =  profile_img_logo rescue nil
      gender =  patient['gender']
      birthday = nil
      unless patient["birthday"].nil?
        split_bday = patient["birthday"].split('/')
        birthday = Date.new(split_bday[2].to_i , split_bday[0].to_i, split_bday[1].to_i)
      end


      fb_detail = company.build_facebook_detail(:first_name => patient["name"].split.first,
                                                :last_name => patient["name"].split.second,
                                                :dob => birthday ,:email => patient["email"],
                                                :address => loc_name ,
                                                :city => city ,
                                                :logo => profile_pic ,
                                                :gender => gender ,
                                                :fb_url => profile_pic
      )
      if fb_detail.valid?
        fb_detail.save
        redirect_to  session[:current_path] , :fb_id => fb_detail.id
      else
        # redirect_to  :back, status: false
      end
    else
      # redirect_to  :back , status: false
    end
  end

  private

  # Getting whole day time into slots of duration of appointment type
  def change_time_into_slots(st_hr, st_min, end_hr, end_min, duration)
    time_range = []

    start_time = DateTime.new(2016,12,12 ,st_hr.to_i , st_min.to_i)
    end_time = DateTime.new(2016,12,12 ,end_hr.to_i , end_min.to_i)

    while (start_time < end_time)
      item = []
      # next_st_hr = ((start_time.strftime("%M").to_i + duration.to_i) >= 60 ? (start_time.strftime("%H").to_i + 1) : (start_time.strftime("%H").to_i))
      if duration.to_i > 60
        aa = Time.parse(start_time.strftime("%H:%M"))
        next_start_time = (Time.parse(start_time.strftime("%H:%M")) + (duration.to_i * 60))
        next_st_hr = next_start_time.strftime("%H").to_i
        next_st_min = next_start_time.strftime("%M").to_i
      else
        min_with_dur = (start_time.strftime("%M").to_i + duration.to_i)
        next_st_hr = (min_with_dur >= 60 ? (start_time.strftime("%H").to_i + 1) : (start_time.strftime("%H").to_i))
        next_st_min = (min_with_dur >= 60 ? (min_with_dur - 60) : (start_time.strftime("%M").to_i + duration.to_i ))
      end
      after_time = DateTime.new(2016,12,12 , next_st_hr ,next_st_min  ) #start_time.to_f + ((duration.to_f)/60.0).round(2)
      if after_time <= end_time
        item << start_time.strftime("%H:%M") #convert_decimal_number_into_time(start_time.round(2))
        item << after_time.strftime("%H:%M") #convert_decimal_number_into_time(after_time.round(2))
        start_time = after_time
        print item
        time_range << item
      else
        start_time = end_time
      end

    end
    return time_range
  end

  # method to change time into decimal number when hour and minutes are available 
  def change_time_into_decimal_number(st_hr, st_min)
    time = st_hr.to_f + ((st_min.to_f)/60.0)
    # print time
  end

  # method to change time into decimal number when time format is available
  def change_time_into_decimal_number_for_time(time)
    arr_time = time.split(":")
    num = (arr_time[0].to_f + ((arr_time[1].to_f)/60.0)).round(2)
  end

  # method to change a decimal number into time 
  def convert_decimal_number_into_time(num)
    arr = (num.to_s).split(".")
    hr_elem = (arr[0].length == 1 ? ("0"+ arr[0]) : arr[0])
    min_elem = (((arr[1].length == 1 ? arr[1]+"0" : arr[1]).to_i)*60.0/100.0).ceil.to_s
    time = hr_elem +":"+ (min_elem.length == 1 ? ("0"+ min_elem) : min_elem)
    return time
  end

  # remove break time slots from available slots
  def remove_slots_in_which_break_slot_exist(time_slots, bk_item)
    del_item = []
    time_slots.each do |tm_slot|

      if (time_exist_in_time_range(bk_item[0], tm_slot))
        unless bk_item[0] == tm_slot[1]
          del_item << tm_slot
        end
      end

      if (time_exist_in_time_range(bk_item[1], tm_slot))
        unless bk_item[1] == tm_slot[0]
          del_item << tm_slot
        end
      end

    end

    del_item.each do |elem|
      time_slots.delete(elem)
    end

    return time_slots
  end

  # checking is a time existing in a time duration
  def time_exist_in_time_range(time, arr_element)
    allowed_ranges = (arr_element[0].to_s)..(arr_element[1].to_s)
    formatted_time = time.to_datetime.strftime("%H:%M")
    flag = ([] << allowed_ranges).any? { |range| range.cover?(formatted_time) }
    return flag
  end

  # time slots classifications as per a date wise or (morning/afternoon/evening)

  def slots_classification(time_slots, flag=false)
    result= {}
    result[:morning_flag] = false
    morning_slots = []
    result[:afternoon_flag] = false
    afternoon_slots = []
    result[:evening_flag] = false
    evening_slots = []

    time_slots.each do |slot|
      if (change_time_into_decimal_number_for_time(slot[0]) >= 0 && change_time_into_decimal_number_for_time(slot[0]) < 12)
        morning_slots << slot
      elsif (change_time_into_decimal_number_for_time(slot[0]) >= 12 && change_time_into_decimal_number_for_time(slot[0]) < 17)
        afternoon_slots << slot
      elsif (change_time_into_decimal_number_for_time(slot[0]) >= 17 && change_time_into_decimal_number_for_time(slot[0]) < 24)
        evening_slots << slot
      end
    end
    result[:morning_flag] = true if morning_slots.length > 0
    result[:afternoon_flag] = true if afternoon_slots.length > 0
    result[:evening_flag] = true if evening_slots.length > 0
    #t1 = Time.now.strftime("%H:%M")

    min_appnt_sttng = @company.online_booking.min_appointment
    result[:morning] = (min_appnt_sttng.to_i ==0 ? morning_slots : morning_slots.first(min_appnt_sttng.to_i)) if flag == true
    result[:afternoon] = (min_appnt_sttng.to_i ==0 ? afternoon_slots : afternoon_slots.first(min_appnt_sttng.to_i)) if flag == true
    result[:evening] = (min_appnt_sttng.to_i ==0 ? evening_slots : evening_slots.first(min_appnt_sttng.to_i)) if flag == true

    return result
  end

  def skip_slot_if_exist_or_insert(time_slots_arr, avail_slot)
    flag = false

    time_slots_arr.each do |tm_slot|
      if (time_exist_in_time_range(avail_slot[0], tm_slot))
        unless avail_slot[0] == tm_slot[1]
          flag = true
        end
      end

      if (time_exist_in_time_range(avail_slot[1], tm_slot))
        unless avail_slot[1] == tm_slot[0]
          flag = true
        end
      end
    end

    if flag == false
      time_slots_arr = time_slots_arr << avail_slot
    end
    return time_slots_arr
  end


  def change_time_in_slots(st_hr, st_min, end_hr, end_min)
    time_range = []
    item = []
    start_time = change_time_into_decimal_number(st_hr, st_min)
    end_time = change_time_into_decimal_number(end_hr, end_min)
    item << convert_decimal_number_into_time(start_time.round(2))
    item << convert_decimal_number_into_time(end_time.round(2))
    time_range << item
    return time_range
  end

  def break_time_slots_when_break_exists(time_slots_arr, bk_item)
    result = []
    flag = false
    time_slots_arr.each do |slot|
      if ((time_exist_in_time_range(slot[0], bk_item)) || (time_exist_in_time_range(slot[1], bk_item))) || ((time_exist_in_time_range(bk_item[0], slot)) || (time_exist_in_time_range(bk_item[1], slot)))
        flag = true
        break
      end
    end
    unless flag
      result = time_slots_arr
    else
      time_slots_arr.each do |slot|
        if !(time_exist_in_time_range(bk_item[0], slot)) && !(time_exist_in_time_range(bk_item[1], slot))
          result << slot
        elsif (time_exist_in_time_range(bk_item[0], slot)) && (time_exist_in_time_range(bk_item[1], slot))
          if (bk_item[0] == slot[0] && bk_item[1] != slot[1])
            result << [bk_item[1], slot[1]]
          elsif (bk_item[0] != slot[0] && bk_item[1] == slot[1])
            result << [slot[0], bk_item[0]]
          elsif (bk_item[0] != slot[0] && bk_item[1] != slot[1])
            result << [slot[0], bk_item[0]]
            result << [bk_item[1], slot[1]]
          end
        elsif !(time_exist_in_time_range(bk_item[0], slot)) && (time_exist_in_time_range(bk_item[1], slot))
          if (bk_item[1] == slot[0])
            result << slot
          elsif (bk_item[0] != slot[0]) && (bk_item[1] != slot[1])
            result << [bk_item[1], slot[1]]
          end
        elsif (time_exist_in_time_range(bk_item[0], slot)) && !(time_exist_in_time_range(bk_item[1], slot))
          if (bk_item[0] == slot[1])
            result << slot
          elsif (bk_item[0] != slot[0]) && (bk_item[1] != slot[1])
            result << [slot[0], bk_item[0]]
          end
        elsif (time_exist_in_time_range(slot[0], bk_item)) && (time_exist_in_time_range(slot[1], bk_item))

        end
      end
    end

    return result
  end

  def clear_passed_slot(time_slots, passed_time_slots,hr,min)
    result = []
    appnt_slot = passed_time_slots.last.last.split(':')
    last_slot = time_slots.last.last.split(':')
    if change_time_into_decimal_number(last_slot.first, last_slot.second) > change_time_into_decimal_number(appnt_slot.first , appnt_slot.second)
      time_slots.each do |slot|
        slot_end_time = slot.last.split(':')
        # [passed_time_slots.last.last , slot.last ]
        start_slot = passed_time_slots.last.last
        if start_slot.split(':').join('.').to_f < slot.first.split(':').join('.').to_f
          start_slot = slot.first
        end
        result << [start_slot , slot.last ] if change_time_into_decimal_number(slot_end_time.first, slot_end_time.second) > change_time_into_decimal_number(appnt_slot.first , appnt_slot.second)
      end
    end
    return result
  end

  # merging availability slots into working time period
  def merge_time_slots(avail_slot, time_slots_arr)
    result = time_slots_arr
    flag = false
    del_item = {}

    time_slots_arr.each do |slot|
      if ((time_exist_in_time_range(slot[0], avail_slot)) || (time_exist_in_time_range(slot[1], avail_slot))) || ((time_exist_in_time_range(avail_slot[0], slot)) || (time_exist_in_time_range(avail_slot[1], slot)))
        flag = true
        break
      end
    end
    if flag
      time_slots_arr.each do |slot|
        unless is_avail_slot_within_time_slot(avail_slot, slot)
          if (time_exist_in_time_range(slot[0], avail_slot)) && (time_exist_in_time_range(slot[1], avail_slot))
            del_item[slot] = avail_slot
          elsif (time_exist_in_time_range(slot[0], avail_slot)) && !(time_exist_in_time_range(slot[1], avail_slot))
            new_slot = [avail_slot[0], slot[1]]
            # result.map! { |x| x == slot ? new_slot : x }.flatten!
            del_item[slot] = new_slot
          elsif !(time_exist_in_time_range(slot[0], avail_slot)) && (time_exist_in_time_range(slot[1], avail_slot))
            new_slot = [slot[0], avail_slot[1]]
            # result.map! { |x| x == slot ? new_slot : x }.flatten!  
            del_item[slot] = new_slot
          end
        end
      end
      del_item.each { |key, value|
        result.map! { |x| x == key ? value : x }
      }
    else
      result << avail_slot
    end

    return result.uniq
  end

  def is_avail_slot_within_time_slot(avail_slot, slot)
    time_exist_in_time_range(avail_slot[0], slot) && time_exist_in_time_range(avail_slot[1], slot)
  end

  def remove_appnt_slot_out_of_time_slot(time_slots, appnt_time_slots)
    result = []
    appnt_time_slots.each do |appnt_slot|
      puts appnt_slot
      flag = false
      time_slots.each do |slot|
        puts slot
        flag = ((time_exist_in_time_range(appnt_slot[0], slot) && appnt_slot[0] != slot[1]) || (time_exist_in_time_range(appnt_slot[1], slot) && appnt_slot[1] != slot[0]))
        break if flag == true
      end
      if flag == false
        result << appnt_slot
      end
    end
    return appnt_time_slots - result
  end

  def urldecode64(str)
    encoded_str = str.tr('-_', '+/')
    encoded_str += '=' while !(encoded_str.size % 4).zero?
    Base64.decode64(encoded_str)
  end

  def parse_signed_request(secret_id, request)
    encoded_sig, payload = request.split('.', 2)
    sig = urldecode64(encoded_sig)
    data = JSON.parse(urldecode64(payload))
    if data['algorithm'].to_s.upcase != 'HMAC-SHA256'
      raise "Bad signature algorithm: %s" % data['algorithm']
    end
    expected_sig = OpenSSL::HMAC.digest('sha256', secret_id, payload)
    if expected_sig != sig
      raise "Bad signature"
    end
    data
  end
end
