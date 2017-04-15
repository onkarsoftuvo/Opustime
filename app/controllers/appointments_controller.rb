class AppointmentsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include Reminder::ReadyMade

  respond_to :json
  before_filter :authorize, :except => [:create_appnt_through_online_booking, :appointment_show_online_booking, :update_partially_booking, :appointment_show_online_booking_pdf, :view_logs]
  before_action :find_company_by_sub_domain, :only => [:index, :create, :edit, :update, :update_partially, :show, :new, :practitioners_availability, :location_wise_available_doctors, :get_appointments_in_time_period, :practitioner_wise_appointment_types,
                                         :calendar_setting, :check_practitioner_availability_for_specific_day_and_time_on_a_location, :get_template_notes , :future_appnt_print]
  before_action :find_appointment, :only => [:appointment_show_online_booking, :appointment_show_online_booking_pdf, :show, :edit, :update, :update_partially, :destroy, :patient_arrival, :update_partially_booking, :view_logs, :get_template_notes , :future_appnt_print]
  before_action :set_params_in_standard_format, :only => [:create, :update, :update_partially, :create_appnt_through_online_booking, :update_partially_booking]

  before_action :find_company_for_booking, :only => [:create_appnt_through_online_booking, :set_params_in_standard_format, :appointment_show_online_booking, :update_partially_booking, :appointment_show_online_booking_pdf]
  before_action :stop_activity
  before_action :check_valid_patient, :only => [:update]

  load_and_authorize_resource param_method: :params_appointment, except: [:create_appnt_through_online_booking, :appointment_show_online_booking, :update_partially_booking, :appointment_show_online_booking_pdf, :check_practitioner_availability_for_specific_day_and_time_on_a_location, :treatment_notes, :get_template_notes, :future_appnt_print]
  before_filter :load_permissions

  # using only for postman to test API. Remove later
  skip_before_filter :verify_authenticity_token, :unless => Proc.new { |c| c.request.format == 'application/json' }

  def index
    begin
      appointments = @company.appointments.active_appointment.order("appointments.created_at desc").select("appointments.id , appointments.appnt_date , appointments.appnt_time_start , appointments.appnt_time_end , appointments.user_id , appointments.patient_id , appointments.created_at , appointments.patient_arrive , appointments.appnt_status, appointments.online_booked")

      result = []
      appointments.each do |appnt|
        item = {}
        item[:id] = appnt.id
        item[:resourceId] = appnt.user.try(:id)
        item[:patient_arrive] = appnt.patient_arrive
        item[:appnt_status] = appnt.appnt_status
        item[:appnt_time_period] = appnt.time_check_format
        # item[:associated_treatment_note] = appnt.treatment_notes.last.try(:id)
        item[:associated_treatment_note_status] = appnt.treatment_notes.last.try(:save_final)
        item[:associated_invoice_status] = appnt.invoice.try(:calculate_outstanding_balance).nil? ? nil : (appnt.invoice.try(:calculate_outstanding_balance).to_i > 0 ? "Outstanding Invoice" : "paid invoice")

        item[:is_notes_avail] = !(appnt.notes.nil?)
        item[:booker_type] = appnt.booker_type
        item[:online_booked] = appnt.online_booked
        date_appnt = appnt.appnt_date.strftime("%a %b %d %Y")

        start_time = date_appnt.to_s + " "+ appnt.appnt_time_start.strftime("%H:%M:%S")
        item[:start] = start_time

        end_time = date_appnt.to_s + " "+ appnt.appnt_time_end.strftime("%H:%M:%S")
        item[:end] = end_time

        item[:title] = appnt.patient.full_name
        item[:color_code] = appnt.appointment_type.try(:color_code)
        item[:reference_number] = appnt.patient.reference_number
        result << item
      end
      render :json => {appointments: result}

    rescue Exception => e
      render :json => {:error => e.message}
    end

  end

  def new
    begin
      @appointment = Appointment.new
      result = {}
      result[:appnt_date] = @appointment.appnt_date
      result[:appnt_time] = @appointment.appnt_time
      result[:repeat_by] = @appointment.repeat_by
      result[:repeat_start] = @appointment.repeat_start
      result[:repeat_end] = @appointment.repeat_end
      result[:notes] = @appointment.notes
      result[:user_id] = @appointment.user_id
      result[:patient_id] = @appointment.patient_id
      render :json => {appointment: result}
    rescue Exception => e
      render :json => {:error => e.message}
    end
  end

  def create
    begin
      unless params[:appointment][:wait_lists_appointment_attributes] == "500"
        if params[:appointment][:repeat_by] == "week" && params[:appointment][:week_days].length > 0
          flag = Appointment.create_appointments_weekly_days_wise(@company, params_appointment)

          Appointment.public_activity_on
          create_activity_log(params_appointment[:patient_id])
          result = {flag: flag}
          render :json => result
        else
          appointment = @company.appointments.new(params_appointment)
          if appointment.valid?
            appointment.unique_key = random_key
            appointment.with_lock do
              appointment.save
            end
            Appointment.public_activity_on
            create_activity_log(params_appointment[:patient_id])
            result = {flag: true, id: appointment.id}
            AppointmentBookingWorker.perform_async(appointment.id, "patient")
            render :json => result
          else
            show_error_json(appointment.errors.messages)
          end
        end
      else
        appnt = Appointment.new
        appnt.errors.add(:To_add_wait_list, ".appointment date must be in future date.")
        show_error_json(appnt.errors.messages)
      end
    rescue Exception => e
      render :json => {:error => e.message}
    end
  end

  def create_appnt_through_online_booking
    appointment = @company.appointments.new(params_appointment)

    if appointment.valid?
      appointment.unique_key = random_key
      appointment.with_lock do
        appointment.save
      end
      Appointment.public_activity_on
      create_activity_log(params_appointment[:patient_id])
      notify_by = @company.online_booking.notify_by.to_s
      patient = appointment.patient
      #  sending email and sms to practitioner
      if (["email", "sms_email"].include? notify_by)
        AppointmentBookingWorker.perform_async(appointment.id)
        AppointmentBookingWorker.perform_async(appointment.id, "patient")
        appointment.send_sms_practitioner if @company.sms_setting.default_sms > 0
      elsif notify_by.eql? "sms"
        appointment.send_sms_practitioner if @company.sms_setting.default_sms > 0
      end

      # SMS and email to patient
      AppointmentBookingWorker.perform_async(appointment.id, "patient")
      appointment.send_sms_practitioner(false) if @company.sms_setting.default_sms > 0
      result = {flag: true, id: appointment.id, comp_id: @company.id}
      render :json => result
    else
      show_error_json(appointment.errors.messages)
    end

  end

  def show
    begin
      result = {}
      unless @appointment.nil?
        result[:id] = @appointment.id
        result[:appointment_type_name] = @appointment.appointment_type.try(:name)
        result[:color_code] = @appointment.appointment_type.try(:color_code)
        result[:practitioner_id] = @appointment.user.try(:id)
        result[:practitioner] = @appointment.user.full_name
        result[:appnt_date_only] = @appointment.appnt_date.to_date.strftime("%Y-%m-%dT") + @appointment.appnt_time_start.strftime("%H:%M:%S")
        apnt_date = @appointment.appnt_date.to_date.strftime("On %A,%d %B %Y").to_s
        apnt_start_time = @appointment.appnt_time_start.strftime("%H:%M%p")
        result[:appnt_date] = apnt_date + "," + apnt_start_time

        start_time = @appointment.appnt_time_start
        end_time = @appointment.appnt_time_end
        appnt_time_duration = Time.diff(start_time, end_time)

        # result[:appnt_duration_hr] = appnt_time_duration[:hour]
        result[:appnt_duration_min] = (appnt_time_duration[:hour].to_i * 60) + appnt_time_duration[:minute]
        result[:appnt_time_period] = @appointment.time_check_format
        #     patient general info
        patient = @appointment.patient
        patient_item = {}
        patient_item[:patient_id] = patient.try(:id)
        patient_item[:patient_name] = patient.try(:full_name)
        patient_item[:patient_gender] = (["Male", "Female", "Not Applicable"].include? patient.try(:gender)) ? patient.try(:gender) : "none"
        patient_item[:concession_name] = Patient.last.concession.try(:name)
        patient_item[:profile_pic] = patient.profile_pic
        patient_item[:profile_pic_flag] = (patient.profile_pic.url.include? 'http') ? true : false
        result[:patient_detail] = patient_item
        result[:business] = @appointment.business.try(:id)
        result[:appnt_status] = @appointment.appnt_status

        # patient info for invoice page
        patient_data = {}
        patient_data[:id] = patient.try(:id)
        patient_data[:title] = patient.try(:title)
        patient_data[:first_name] = patient.try(:first_name)
        patient_data[:last_name] = patient.try(:last_name)
        result[:patient] = patient_data

        appnt_detail = {}
        appnt_detail[:appointment_id] = @appointment.id
        appnt_date_m = @appointment.appnt_date.strftime("%d %b %Y")
        appnt_time_m = @appointment.appnt_time_start.strftime("%H:%M%p")
        full_name = appnt_date_m + ", " + appnt_time_m + " - " + @appointment.appointment_type.try(:name)
        appnt_detail[:appointment_name] = full_name

        appnt_detail[:appointment_type_id] = @appointment.appointment_type.try(:id)
        appnt_detail[:appointment_type_name] = @appointment.appointment_type.try(:name)
        result[:appnt_info] = appnt_detail
        result[:type] = "appointment"

        # till here

        result[:email] = patient.try(:email)
        #     patient contact info
        contacts = patient.patient_contacts.select("contact_no , contact_type")
        contacts_fax = patient.patient_contacts.where(["patient_contacts.contact_type= ?", "fax"])
        contact_items = []
        contacts.each do |contact|
          unless contact.contact_type == "fax"
            item = {}
            item[:contact_no] = contact.contact_no.phony_formatted(format: :international, spaces: '-')
            item[:contact_type] = contact.contact_type.downcase
            contact_items << item
          end
        end
        result[:patient_contact_info] = contact_items
        if contacts_fax.count > 0
          result[:fax_no] = contacts_fax.first.contact_no
        else
          result[:fax_no] = nil
        end
        result[:next_appointment_date] = []
        #     finding next available appointment
        next_appointment = patient.appointments.where(["(Date(appnt_date) >= ? AND appnt_time_start  > CAST(?  AS time) AND status= ?) OR (Date(appnt_date) > ? AND status= ?) ", @appointment.appnt_date, @appointment.appnt_time_start, true, @appointment.appnt_date, true]).order("appnt_date asc, appnt_time_start asc").limit(2)
        next_appointment.each do |next_apnt|
          item = {}
          item[:next_appointment_id] = next_apnt.id
          item[:next_appointment_date] = next_apnt.appnt_date.to_date.strftime("%a,%d %B %Y")
          item[:next_appointment_time] = next_apnt.appnt_time_start.strftime("%H:%M %P")
          item[:practitioner_id] = next_apnt.user.try(:id)
          item[:practitioner] = next_apnt.user.full_name
          result[:next_appointment_date] << item
        end
        create_time = @appointment.created_at.strftime("%d %b %Y,%H:%M%P")
        update_time = @appointment.updated_at.strftime("%d %b %Y,%H:%M%P")
        if create_time == update_time
          result[:created_at] = create_time
          result[:updated_at] = nil
        else
          result[:updated_at] = update_time
          result[:created_at] = nil
        end
        #     Data for four buttons on show appointment
        result[:patient_arrive] = @appointment.patient_arrive
        result[:credit_amount] = '% .2f'% (@appointment.patient.calculate_patient_credit_amount.round(2)).to_f
        result[:Outstanding_bal] = '% .2f'% (@appointment.patient.calculate_patient_outstanding_balance.round(2)).to_f
        result[:appointment_invoice] = @appointment.paid_or_outstanding_invoice.try(:id)
        result[:has_opened_invoice] = @appointment.has_due_invoice?
        result[:appointment_treatment_note] = @appointment.treatment_notes.last.try(:id)
        result[:appointment_treatment_note_status] = @appointment.treatment_notes.last.try(:save_final)
        result[:notes] = @appointment.notes
        result[:has_series] = @appointment.has_series
        result[:is_cancel] = !(@appointment.cancellation_time.nil?)
      end
      render :json => {appointment: result}

    rescue Exception => e
      render :json => {:error => e.message}
    end
  end

  def appointment_show_online_booking
    result = {}
    business_info = {}
    business = @appointment.try(:business)
    business_info[:id] = business.try(:id)
    business_info[:name] = business.try(:name)
    business_info[:city] = business.try(:city)
    business_info[:full_address] = business.try(:full_address)
    business_info[:web_url] = business.try(:web_url)
    result[:business_info] = business_info
    result[:patient_token] = @appointment.try(:patient).try(:token)

    service = @appointment.appointment_type
    service_info = {}
    service_info[:id] = service.id
    service_info[:service_name] = service.name
    service_info[:category] = service.category
    service_info[:description] = service.description
    service_info[:duration_time] = service.duration_time
    service_info[:duration] = @appointment.try(:user).try(:company).try(:online_booking).try(:hide_end_time)
    result[:service_info] = service_info

    doctor = @appointment.user
    doctor_info = {}
    doctor_info[:id] = doctor.try(:id)
    doctor_info[:name] = doctor.try(:full_name_with_title)
    doctor_info[:designation] = doctor.try(:practi_info).try(:designation)
    doctor_info[:desc] = doctor.practi_info.try(:desc)
    result[:doctor_info] = doctor_info

    result[:appnt_date] = @appointment.appnt_date.strftime("%a, %d %b %Y")
    result[:appnt_date_sc] = @appointment.appnt_date.strftime("%Y-%m-%d")
    result[:appnt_at] = @appointment.appnt_time_start.strftime("%H:%M%p")


    render :json => result

  end

  def appointment_show_online_booking_pdf
    result = {}
    @business = @appointment.business
    @service = @appointment.appointment_type
    @doctor = @appointment.user
    @account_logo_url = @doctor.company.try(:account).try(:logo).try(:url)

    @rate = 0
    if @service.billable_items.length > 0
      @service.billable_items.each do |bill_item|
        @rate = @rate + bill_item.price.to_i
      end
    end

    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => "pdf_name.pdf",
               :layout => '/layouts/pdf.html.erb',
               :disposition => 'inline',
               :template => "/appointments/appointment_show_online_booking_pdf",
               :show_as_html => false,
               :footer => {right: '[page] of [topage]'}

      end
    end
  end

  def edit
    begin
      result = {}
      result[:id] = @appointment.id
      result[:user_id] = @appointment.user.try(:id)
      result[:user_name] = @appointment.user.try(:full_name)
      result[:patient_id] = @appointment.patient.try(:id)
      result[:patient_name] = @appointment.patient.try(:full_name)
      info = {}
      appnt_type = @appointment.appointment_type
      info[:id] = appnt_type.id
      info[:name] = appnt_type.name
      info[:duration_time] = appnt_type.duration_time.to_i
      info[:category] = appnt_type.category.nil? ? "Other" : appnt_type.category
      info[:color_code] = appnt_type.color_code

      result[:appointment_type_info] = info

      result[:appnt_date] = @appointment.appnt_date.strftime("%Y-%m-%d")
      result[:start_hr] = @appointment.appnt_time_start.strftime("%H").to_i
      result[:start_min] = @appointment.appnt_time_start.strftime("%M").to_i
      result[:end_hr] = @appointment.appnt_time_end.strftime("%H").to_i
      result[:end_min] = @appointment.appnt_time_end.strftime("%M").to_i
      result[:repeat_by] = @appointment.repeat_by
      result[:repeat_start] = @appointment.repeat_start

      if @appointment.repeat_by == "week"
        result[:repeat_end] = @appointment.get_total_week_no+1
      else
        result[:repeat_end] = @appointment.siblings_in_series
      end

      result[:notes] = @appointment.notes
      result[:has_series] = @appointment.has_series
      days_arr = @appointment.week_days
      days_arr.map! { |x| x == 7 ? 0 : x }.flatten!

      result[:week_days] = days_arr

      render :json => {appointment: result}
    rescue Exception => e
      render :json => {:error => e.message}
    end

  end

  def update
    begin
      if @valid_patient == true
        # update functionality when only this appointment is selected
        if params[:appointment][:flag].to_i == 0 || params[:appointment][:flag].nil?

          if @appointment.has_series || params[:appointment][:repeat_by].nil?
            updated_params_appointment = occurrence_parameters_same(@appointment, params_appointment)
            @appointment.update_attributes(updated_params_appointment)
            if @appointment.valid?
              result = {:flag => true, :id => @appointment.id}

              Appointment.public_activity_on
              create_all_types_logs(@appointment, true)

              render :json => result
            else
              show_error_json(@appointment.errors.messages)
            end
          else
            params[:appointment].delete "id" if params[:appointment]["id"].present?
            business = @appointment.business
            @appointment.destroy
            if params[:appointment][:repeat_by] == "week" && params[:appointment][:week_days].length > 0
              flag = Appointment.create_appointments_weekly_days_wise(@company, params_appointment, business)

              update_activity_log(params_appointment[:patient_id])

              result = {flag: flag}
              render :json => result
            else
              appointment = @company.appointments.new(params_appointment)
              if appointment.valid?
                appointment.unique_key = random_key
                appointment.business = business
                appointment.with_lock do
                  appointment.save
                end

                create_activity_log(params_appointment[:patient_id])

                result = {flag: true, id: appointment.id}
                render :json => result
              else
                show_error_json(appointment.errors.messages)
              end
            end
          end
        elsif params[:appointment][:flag].to_i == 1 # when following option is selected
          series_item_no = params[:appointment][:repeat_end].to_i
          repeat_by_val = params[:appointment][:repeat_by]

          # has same child appointments 
          if @appointment.has_same_item_series(series_item_no, repeat_by_val, params[:appointment][:repeat_start], params[:appointment][:week_days])

            # checking repeat by value is same or not 
            if @appointment.repeat_by.to_s.casecmp(params[:appointment][:repeat_by]) == 0
              @appointment.update_attributes(params_appointment)
              if @appointment.valid?
                flag = @appointment.reflect_same_in_all_following
                update_activity_log(params_appointment[:patient_id])
                result = {:flag => flag, :id => @appointment.id}
                render :json => result
              else
                show_error_json(@appointment.errors.messages)
              end
            else
              params[:appointment].delete "id" if params[:appointment]["id"].present?
              appointment = @company.appointments.new(params_appointment)
              if appointment.valid?
                business = @appointment.business
                @appointment.remove_following_including_itself

                if params[:appointment][:repeat_by] == "week"
                  flag = Appointment.create_appointments_weekly_days_wise(@company, params_appointment, business)

                  create_activity_log(params_appointment[:patient_id])

                  result = {flag: flag}
                  render :json => result
                else
                  flag = create_appointment_manually(params_appointment, business)
                  create_activity_log(params_appointment[:patient_id])

                  render :json => {flag: flag}
                end

              else
                show_error_json(appointment.errors.messages)
              end
            end
          else
            params[:appointment].delete "id" if params[:appointment]["id"].present?
            appointment = @company.appointments.new(params_appointment)
            if appointment.valid?
              business = @appointment.business
              @appointment.remove_following_including_itself

              if params[:appointment][:repeat_by] == "week"
                flag = Appointment.create_appointments_weekly_days_wise(@company, params_appointment, business)
                create_activity_log(params_appointment[:patient_id])
                result = {flag: flag}
                render :json => result
              else
                flag = create_appointment_manually(params_appointment, business)
                create_activity_log(params_appointment[:patient_id])
                render :json => {flag: flag}
              end
            else
              show_error_json(appointment.errors.messages)
            end
          end

        elsif params[:appointment][:flag].to_i == 2
          series_item_no = params[:appointment][:repeat_end].to_i
          repeat_by_val = params[:appointment][:repeat_by]
          if @appointment.has_same_item_series(series_item_no, repeat_by_val, params[:appointment][:repeat_start], params[:appointment][:week_days])

            if @appointment.repeat_by.to_s.casecmp(params[:appointment][:repeat_by])== 0
              if @appointment.inverse_childappointment.nil?
                @appointment.update_attributes(params_appointment)
                flag = @appointment.reflect_same_in_all_following
                update_activity_log(params_appointment[:patient_id])
                render :json => {flag: flag}
              else
                @appointment.update_attributes(params_appointment)
                @appointment.same_all_events_child
                update_activity_log(params_appointment[:patient_id])
                render :json => {flag: true}
              end
            else
              params[:appointment].delete "id" if params[:appointment]["id"].present?
              appointment = @company.appointments.new(params_appointment)
              if appointment.valid?
                business = @appointment.business
                @appointment.remove_following_including_itself

                if params[:appointment][:repeat_by] == "week"
                  flag = Appointment.create_appointments_weekly_days_wise(@company, params_appointment, business)
                  create_activity_log(params_appointment[:patient_id])
                  result = {flag: flag}
                  render :json => result
                else
                  flag = create_appointment_manually(params_appointment, business)
                  update_activity_log(params_appointment[:patient_id])
                  render :json => {flag: flag}
                end
              else
                show_error_json(appointment.errors.messages)
              end
            end
          else
            params[:appointment].delete "id" if params[:appointment]["id"].present?
            appointment = @company.appointments.new(params_appointment)
            if appointment.valid?
              business = @appointment.business
              @appointment.remove_following_including_itself

              if params[:appointment][:repeat_by] == "week"
                flag = Appointment.create_appointments_weekly_days_wise(@company, params_appointment, business)
                create_activity_log(params_appointment[:patient_id])
                result = {flag: flag}
                render :json => result
              else
                flag = create_appointment_manually(params_appointment, business)
                create_activity_log(params_appointment[:patient_id])
                render :json => {flag: flag}
              end
            else
              show_error_json(appointment.errors.messages)
            end
          end
        end
      else
        apnt = Appointment.new
        apnt.errors.add(:patient, "not found")
        show_error_json(apnt.errors.messages)
      end


    rescue Exception => e
      render :json => {:error => e.message}
    end

  end

  # this action is handling - move , stretch , cancel , reschedule , patient arrive/not , appnt complete or pending 
  def update_partially
    # checking when appointment is not cancelled
    if params[:appointment][:reason].nil?
      @appointment.update_attributes(params_appointment)
      if @appointment.valid?

        Appointment.public_activity_on
        create_all_types_logs(@appointment, false)
        result = {:flag => true, :id => @appointment.id}
        render :json => result
      else
        show_error_json(@appointment.errors.messages)
      end
    else
      @appointment.update_attributes(:cancellation_notes => params[:appointment][:notes], :reason => params[:appointment][:reason], cancellation_time: DateTime.now, "canceller_type" => params_appointment["rescheduler_type"], "canceller_id" => params_appointment["rescheduler_id"])

      Appointment.public_activity_on
      @appointment.create_activity :Cancel, parameters: {reason: @appointment.reason}
      if @appointment.valid?
        Appointmentmailer.sidekiq_delay.appointment_cancellation(@appointment.id)
        Appointmentmailer.sidekiq_delay.appointment_cancellation_for_patient(@appointment.id)

        # AppointmentCancellationsWorker.perform_async(@appointment.id) # background job to send email
        render :json => {flag: true}
      else
        show_error_json(@appointment.errors.messages)
      end
    end
  end

  # this action is handling - move , stretch , cancel , reschedule , patient arrive/not , appnt complete or pending 
  def update_partially_booking
    # checking when appointment is not cancelled
    if params[:appointment][:reason].nil?
      @appointment.update_attributes(params_appointment)
      if @appointment.valid?
        Appointment.public_activity_on
        create_all_types_logs(@appointment, false)
        result = {:flag => true, :id => @appointment.id}
        Appointmentmailer.sidekiq_delay.doctor_reschedule_appointment(@appointment.id)
        Appointmentmailer.sidekiq_delay.reschedule_appointment(@appointment.id)
        render :json => result
      else
        show_error_json(@appointment.errors.messages)
      end
    else
      @appointment.update_attributes(:status => false, :cancellation_notes => params[:appointment][:notes], :reason => params[:appointment][:reason], cancellation_time: DateTime.now, "canceller_type" => params_appointment["rescheduler_type"], "canceller_id" => params_appointment["rescheduler_id"])
      if @appointment.valid?
        Appointment.public_activity_on
        @appointment.create_activity :Cancel, parameters: {reason: @appointment.reason}
        Appointmentmailer.sidekiq_delay.appointment_cancellation(@appointment.id)
        Appointmentmailer.sidekiq_delay.appointment_cancellation_for_patient(@appointment.id)

        render :json => {flag: true, :company_id => Appointment.last.patient.company_id}
      else
        show_error_json(@appointment.errors.messages)
      end
    end
  end

  def destroy
    begin
      if params[:flag].to_i == 0
        @appointment.update_attributes(:status => false)
        if @appointment.valid?
          result = {flag: true, id: @appointment.id}
          Appointment.public_activity_on
          @appointment.create_activity :delete, parameters: {total_appnts: 1, type_wise: nil, patient_id: @appointment.patient.try(:id), patient_name: @appointment.patient.try(:full_name), doctor_id: @appointment.user.try(:id), doctor_name: @appointment.user.try(:full_name), booking_date: @appointment.date_and_time_without_name, other: @appointment.accurate_activity_log_text_reschedule}
          render :json => result
        else
          show_error_json(@appointment.errors.messages)
        end
      elsif params[:flag].to_i == 1
        folowing_series = @appointment.following_series_length
        @appointment.status_change_itself_and_following_appointments_for_delete
        Appointment.public_activity_on
        @appointment.create_activity :delete, parameters: {total_appnts: folowing_series, type_wise: nil, patient_id: @appointment.patient.try(:id), patient_name: @appointment.patient.try(:full_name), doctor_id: @appointment.user.try(:id), doctor_name: @appointment.user.try(:full_name), booking_date: @appointment.date_and_time_without_name, other: @appointment.accurate_activity_log_text_reschedule}
        result = {flag: true}
        render :json => result
      elsif params[:flag].to_i == 2
        folowing_series = @appointment.following_series_length
        @appointment.status_change_for_all_appnt_in_series
        Appointment.public_activity_on
        @appointment.create_activity :delete, parameters: {total_appnts: folowing_series, type_wise: nil, patient_id: @appointment.patient.try(:id), patient_name: @appointment.patient.try(:full_name), doctor_id: @appointment.user.try(:id), doctor_name: @appointment.user.try(:full_name), booking_date: @appointment.date_and_time_without_name, other: @appointment.accurate_activity_log_text_reschedule}
        result = {flag: true}
        render :json => result
      end
    rescue Exception => e
      render :json => {:error => e.message}
    end

  end

  def patient_arrival
    begin
      @appointment.update_attributes(patient_arrive: params[:arrive]) unless params[:arrive].nil?
      if @appointment.valid?
        result = {flag: true, :arrive => @appointment.patient_arrive}
        render :json => result
      else
        show_error_json(@appointment.errors.messages)
      end
    rescue Exception => e
      render :json => {:error => e.message}
    end
  end

  # Checking doctors availabilities in days and their breaks
  def practitioners_availability
    result = []
    user_ids = []
    user_ids = params[:doctors].split(",")

    cal_start_time = @company.account[:calendar_setting]["time_range"]["min_time"]
    cal_end_time = @company.account[:calendar_setting]["time_range"]["max_time"]
    calendar_time_range = [cal_start_time..cal_end_time]

    unless params[:business_id].nil?
      business_id = params[:business_id]
      if user_ids.length > 0
        doctors = @company.users.doctors.joins(practitioner_avails: [:days]).where(["users.id IN (?) AND practitioner_avails.business_id = ? AND days.is_selected = ?", user_ids, business_id, true]).uniq.select("users.id , users.title , users.first_name , users.last_name")
      else
        doctors = @company.users.doctors.joins(practitioner_avails: [:days]).where(["practitioner_avails.business_id = ? AND days.is_selected = ?", business_id, true]).uniq.select("users.id , users.title , users.first_name , users.last_name")
      end
    end
    doctors.each do |doctor|
      item = {}
      item[:id] = doctor.id
      item[:name] = doctor.full_name_with_title
      item[:days] = []
      item[:out_of_service_time] = []
      availability = doctor.practitioner_avails.where(["practitioner_avails.business_id = ? ", business_id]).first
      availability.days.each do |day|
        day_item = {}
        day_item[:id] = day.id
        day_item[:day] = day.day_name
        day_item[:day_index] = DateTime.parse(day.day_name).wday
        day_item[:start] = day.start_hr + ":" + day.start_min
        day_item[:end] = day.end_hr + ":" + day.end_min
        day_item[:is_avail] = day.is_selected

        # Getting out of service time
        if day_item[:is_avail] == true
          out_of_service_time_item_slots = {}
          out_of_service_time_item_slots[:day] = day.day_name
          out_of_service_time_item_slots[:time_range] = []

          service_time_item = {}
          service_time_item[:start_time] = cal_start_time + ":0"
          service_time_item[:end_time] = day.start_hr + ":" + day.start_min
          out_of_service_time_item_slots[:time_range] << service_time_item
        else
          out_of_service_time_item_slots = {}
          out_of_service_time_item_slots[:day] = day.day_name
          out_of_service_time_item_slots[:time_range] = []

          service_time_item = {}
          service_time_item[:start_time] = cal_start_time + ":0"
          service_time_item[:end_time] = cal_end_time + ":0"
          out_of_service_time_item_slots[:time_range] << service_time_item
        end
        if day.is_selected == true
          day_item[:breaks] = []
          day_breaks = day.practitioner_breaks
          day_breaks.each do |day_break|
            break_item = {}
            break_item[:id] = day_break.id
            break_item[:start] = day_break.start_hr + ":" + day_break.start_min
            break_item[:end] = day_break.end_hr + ":" + day_break.end_min

            day_item[:breaks] << break_item

            # adding breaks as out of service time
            service_time_item = {}
            service_time_item[:start_time] = break_item[:start]
            service_time_item[:end_time] = break_item[:end]
            out_of_service_time_item_slots[:time_range] << service_time_item
          end
        end

        # adding out of service time
        if day_item[:is_avail] == true
          service_time_item = {}
          service_time_item[:start_time] = day_item[:end]
          service_time_item[:end_time] = cal_end_time + ":0"
          out_of_service_time_item_slots[:time_range] << service_time_item
        end


        item[:out_of_service_time] << out_of_service_time_item_slots

        item[:days] << day_item

        # Getting practitioner's one off availabilities
        item[:one_off_availability] = []
        start_date = params[:start_date].to_date unless params[:start_date].nil?
        end_date = params[:end_date].to_date unless params[:end_date].nil?
        unless start_date.nil? && end_date.nil?
          one_off_avails = doctor.availabilities.where(["availabilities.is_block = ? AND availabilities.status = ? AND Date(availabilities.avail_date) >= ? AND Date(availabilities.avail_date) <= ? ", false, true, start_date, end_date]).order("avail_date  asc").order("avail_time_start asc")
        else
          one_off_avails = doctor.availabilities.joins(:business).where(['is_block = ? AND status = ? AND businesses.id = ? ', false, true, business_id])..order("avail_date  asc").order("avail_time_start asc")
        end

        one_off_avails.each do |one_off_record|
          one_off_item = {}
          one_off_item[:id] = one_off_record.id
          avail_date = one_off_record.avail_date.strftime("%Y-%m-%dT") unless one_off_record.avail_date.nil?
          avail_start = one_off_record.avail_time_start.strftime("%H:%M:%S") unless one_off_record.avail_time_start.nil?
          avail_end = one_off_record.avail_time_end.strftime("%H:%M:%S") unless one_off_record.avail_time_end.nil?
          one_off_item[:one_off_start] = avail_date.to_s + avail_start.to_s
          one_off_item[:one_off_end] = avail_date.to_s + avail_end.to_s

          # removing one_off_availability from out of service time
          if item[:out_of_service_time].length == 7
            unless one_off_record.avail_date.nil?
              day_name = one_off_record.avail_date.strftime("%A")
              replace_existing_time_slot_in_out_service_time(day_name, one_off_item[:one_off_start], one_off_item[:one_off_end], item[:out_of_service_time])
            end
          end

          item[:one_off_availability] << one_off_item
        end

        # Getting practitioner's one off unavailabilities
        item[:unavailable_block] = []

        unavailable_blocks = doctor.availabilities.joins(:business).where(['is_block = ? AND status = ? AND businesses.id = ? ', true, true, business_id]).order("avail_date  asc").order("avail_time_start asc")
        unavailable_blocks.each do |unavail_record|
          unavail_item = {}
          unavail_item[:id] = unavail_record.id
          avail_date = unavail_record.avail_date.strftime("%Y-%m-%dT") unless unavail_record.avail_date.nil?
          avail_start = unavail_record.avail_time_start.strftime("%H:%M:%S") unless unavail_record.avail_time_start.nil?
          avail_end = unavail_record.avail_time_end.strftime("%H:%M:%S") unless unavail_record.avail_time_end.nil?
          unavail_item[:one_off_start] = avail_date.to_s + avail_start.to_s
          unavail_item[:one_off_end] = avail_date.to_s + avail_end.to_s
          # unavail_item[:repeat_by] = unavail_record.repeat
          # unavail_item[:repeat_start] = unavail_record.repeat_every
          item[:unavailable_block] << unavail_item
        end

      end
      result << item
    end
    render :json => {:practitioners_availability_info => result}
  end

  #   Getting doctors list those are available in a location
  def location_wise_available_doctors
    begin
      unless params[:business_id].nil?
        business_id = params[:business_id]
        doctors = @company.users.doctors.joins(practitioner_avails: [:days]).where(["practitioner_avails.business_id = ? AND days.is_selected = ?", business_id, true]).uniq.select("users.id , users.title , users.first_name , users.last_name")
      end
      result = []
      doctors.each do |doctor|
        item = {}
        item[:id] = doctor.id
        item[:name] = doctor.full_name
        item[:first_name] = doctor.first_name
        result << item
      end
      render :json => {:available_practitioners => result}
    rescue Exception => e
      render :json => {:error => e.message}
    end
  end

  #   Adding functionality for a doctor to check - is he/she available on a specific time on a business location
  def check_practitioner_availability_for_specific_day_and_time_on_a_location
    flag = true
    time_slots = []
    unless !(Date.valid_date?(params[:y].to_i, params[:m].to_i, params[:d].to_i)) || params[:start_hr].nil? || params[:start_min].nil? || params[:end_hr].nil? || params[:end_min].nil?
      doctor = @company.users.doctors.find_by_id(params[:id])
      appointment_type = @company.appointment_types.find_by_id(params[:appointment_type])
      unless params[:y].nil? && params[:m].nil? & params[:d].nil?
        dt = Date.new(params[:y].to_i, params[:m].to_i, params[:d].to_i)
        unless doctor.nil? && appointment_type.nil?
          doctor_avail = doctor.practitioner_avails.where(business_id: params[:b_id]).first
          # duration_time = appointment_type.duration_time
          days = doctor_avail.days
          days.each do |day|
            if dt.strftime("%A").casecmp(day.day_name) == 0
              if day.is_selected == true
                time_slots = change_time_in_slots(day.start_hr, day.start_min, day.end_hr, day.end_min)
                day_breaks = day.practitioner_breaks
                day_breaks.each do |bk|
                  bk_item = []
                  break_st_time = change_time_into_decimal_number(bk.start_hr, bk.start_min)
                  bk_item << convert_decimal_number_into_time(break_st_time)
                  break_end_time = change_time_into_decimal_number(bk.end_hr, bk.end_min)
                  bk_item << convert_decimal_number_into_time(break_end_time)
                  time_slots = break_time_slots_when_break_exists(time_slots, bk_item) #remove_slots_in_which_break_slot_exist(time_slots , bk_item)
                  # temp << bk_item
                end
              end
              # if any one-off availability exists and does not include in time slots then include that one
              one_off_avails = doctor.availabilities.extra_avails.joins(:business).where(["businesses.id = ? and DATE(avail_date) = ? ", params[:b_id], dt])
              avail_time_slots = []
              one_off_avails.each do |avail|
                avail_time_slots = avail_time_slots + change_time_in_slots(avail.avail_time_start.strftime("%H"), avail.avail_time_start.strftime("%M"), avail.avail_time_end.strftime("%H"), avail.avail_time_end.strftime("%M"))
              end
              avail_time_slots.each do |avail_slot|
                time_slots = merge_time_slots(avail_slot, time_slots)
              end
              # item[:avail_time_slots] = avail_time_slots

              # if any un-availability exists
              unavails_periods = doctor.availabilities.extra_unavails.joins(:business).where(["businesses.id = ? and DATE(avail_date) = ? ", params[:b_id], dt])
              unavail_time_slots = []
              unavails_periods.each do |unavail|
                unavail_time_slots = unavail_time_slots + change_time_in_slots(unavail.avail_time_start.strftime("%H"), unavail.avail_time_start.strftime("%M"), unavail.avail_time_end.strftime("%H"), unavail.avail_time_end.strftime("%M"))
              end
              unavail_time_slots.each do |unavail_slot|
                time_slots = break_time_slots_when_break_exists(time_slots, unavail_slot)
              end


              # checking is there any appointment on the same day

              if params[:currentAppId].present?
                appnts = doctor.appointments.joins(:business).where(["businesses.id = ? AND DATE(appnt_date) = ? AND appointments.id NOT IN (?) AND cancellation_time IS ?", params[:b_id], dt, [params[:currentAppId]], nil]).active_appointment.uniq
              else
                appnts =doctor.appointments.joins(:business).where(["businesses.id = ? AND DATE(appnt_date) = ? AND cancellation_time IS ?", params[:b_id], dt, nil]).active_appointment.uniq
              end


              appnt_time_slots = []
              appnts.each do |appnt|
                appnt_time_slots = appnt_time_slots + change_time_in_slots(appnt.appnt_time_start.strftime("%H"), appnt.appnt_time_start.strftime("%M"), appnt.appnt_time_end.strftime("%H"), appnt.appnt_time_end.strftime("%M"))
              end

              appnt_time_slots = remove_appnt_slot_out_of_time_slot(time_slots, appnt_time_slots)
              appnt_time_slots.each do |appnt_slot|
                time_slots = break_time_slots_when_break_exists(time_slots, appnt_slot)
              end
            end
          end
        end
        start_time = (params[:start_hr].length > 1 ? params[:start_hr] : "0#{params[:start_hr]}") + ":" + (params[:start_min].length > 1 ? params[:start_min] : "0#{params[:start_min]}")
        end_time = (params[:end_hr].length > 1 ? params[:end_hr] : "0#{params[:end_hr]}") + ":" + (params[:end_min].length > 1 ? params[:end_min] : "0#{params[:end_min]}")
        flag = check_existance_of_time_into_time_range(start_time, end_time, time_slots)
      else
        flag = false
      end
    else
      flag = false
    end
    render :json => {flag: flag, doctor: doctor.full_name}


  end

  #   Appointments when calendar date is selected
  def get_appointments_in_time_period
    begin
      result = []
      user_ids = []
      appointments = []
      user_ids = params[:doctors].split(",")
      start_date = params[:start_date].nil? ? Date.today : params[:start_date].to_date
      end_date = params[:end_date].nil? ? Date.today : params[:end_date].to_date
      unless params[:business_id].nil?
        business_id = params[:business_id]
        business = Business.find_by_id(business_id)
        if user_ids.length > 0
          doctors = @company.users.doctors.joins(practitioner_avails: [:days]).where(["users.id IN (?) AND practitioner_avails.business_id = ? AND days.is_selected = ?", user_ids, business_id, true]).uniq.select("users.id , users.title , users.first_name , users.last_name")
        else
          doctors = @company.users.doctors.joins(practitioner_avails: [:days]).where(["practitioner_avails.business_id = ? AND days.is_selected = ?", business_id, true]).uniq.select("users.id , users.title , users.first_name , users.last_name")
        end
      end
      doctors_id = doctors.length > 0 ? doctors.ids : user_ids

      # Getting filters values
      patient_arrive_filter = invoice_filter = treatment_note_filter = appointment_complete_filter = patient_future_appointment = nil
      if params[:patient_arrival] == "true" && params[:patient_not_arrival] == "false"
        patient_arrive_filter = true
      elsif params[:patient_arrival] == "false" && params[:patient_not_arrival] == "true"
        patient_arrive_filter = false
      end
      if params[:invoice_paid] == "true" && params[:outstanding_invoice] == "false"
        invoice_filter = true
      elsif params[:invoice_paid] == "false" && params[:outstanding_invoice] == "true"
        invoice_filter = false
      end

      if params[:tr_note_final] == "true" && params[:tr_note_draft] == "false"
        treatment_note_filter = true
      elsif params[:tr_note_final] == "false" && params[:tr_note_draft] == "true"
        treatment_note_filter = false
      end

      if params[:appnt_complete] == "true" && params[:appnt_pending] == "false"
        appointment_complete_filter = true
      elsif params[:appnt_complete] == "false" && params[:appnt_pending] == "true"
        appointment_complete_filter = false
      end

      if params[:appnt_future] == "true" && params[:no_appnt_future] == "false"
        patient_future_appointment = true
      elsif params[:appnt_future] == "false" && params[:no_appnt_future] == "true"
        patient_future_appointment = false
      end


      invoices = business.invoices
      unless invoice_filter.nil?
        filter_based_invoices_ids = invoices_paid_or_unpaid(invoice_filter, invoices)
      end
      appointments = filteration_appointments(patient_arrive_filter, invoice_filter, treatment_note_filter, appointment_complete_filter, patient_future_appointment, filter_based_invoices_ids, doctors_id, business_id, start_date, end_date)

      appointments.active_appointment.each do |appnt|
        item = {}
        item[:id] = appnt.id
        item[:resourceId] = appnt.user.try(:id)
        patient = appnt.patient
        item[:patient_id] = patient.try(:id)
        item[:patient_gender] = (["Male", "Female", "Not Applicable"].include? patient.try(:gender)) ? patient.try(:gender) : "none"
        item[:patient_arrive] = appnt.patient_arrive
        item[:profile_pic] = patient.profile_pic
        item[:profile_pic_flag] = (patient.profile_pic.url.include? 'http') ? true : false
        item[:appnt_status] = appnt.appnt_status
        item[:appnt_time_period] = appnt.time_check_format
        item[:associated_treatment_note] = appnt.treatment_notes.last.try(:id)
        item[:associated_treatment_note_status] = appnt.treatment_notes.last.try(:save_final)
        item[:associated_invoice_status] = appnt.invoices.length == 0 ? nil : (appnt.paid_or_outstanding_invoice.try(:calculate_outstanding_balance).to_i > 0 ? "Outstanding Invoice" : "paid invoice")
        item[:is_notes_avail] = !(appnt.notes.blank?)

        date_appnt = appnt.appnt_date.strftime("%a %b %d %Y")

        start_time = date_appnt.to_s + " "+ appnt.appnt_time_start.strftime("%H:%M:%S")
        item[:start] = start_time

        end_time = date_appnt.to_s + " "+ appnt.appnt_time_end.strftime("%H:%M:%S")
        item[:end] = end_time
        item[:title] = appnt.patient.full_name
        item[:appointment_type_id] = appnt.appointment_type.try(:id)
        item[:appointment_type_name] = appnt.appointment_type.try(:name)
        item[:practitioner_name] = appnt.user.try(:full_name_with_title)
        item[:color_code] = appnt.appointment_type.try(:color_code)
        item[:is_cancel] = !(appnt.cancellation_time.nil?)
        item[:online_booked] = appnt.online_booked
        item[:reference_number] = patient.reference_number
        result << item
      end
      render :json => {appointments: result}
    rescue Exception => e
      render :json => {:error => e.message}
    end

  end

  def practitioner_wise_appointment_types
    result = {}
    doctor = @company.users.doctors.find_by_id(params[:practitioner_id])
    result[:appointment_types] = []

    #  doctor may be exists or not
    unless doctor.nil?
      all_appnts_ids = doctor.appointment_types.ids
      default_appnt_id = doctor.practi_info.default_type.to_i == 0 ? nil : doctor.practi_info.default_type.to_i
      unless default_appnt_id.nil?
        if all_appnts_ids.include?(default_appnt_id.to_i)
          result[:default_appointment_type] = default_appnt_id.to_i
        else
          result[:default_appointment_type] = nil
        end
      else
        result[:default_appointment_type] = nil
      end


      appointment_types = doctor.appointment_types.select("appointment_types.id , appointment_types.name , appointment_types.color_code , appointment_types.duration_time , appointment_types.category ")

      # When doctor does not have any appointment type then all types of appoitment given by company will be shown
      if appointment_types.length > 0
        appointment_types.each do |appnt_type|
          item = {}
          item[:id] = appnt_type.id
          item[:name] = appnt_type.name
          item[:color_code] = appnt_type.color_code
          item[:duration_time] = appnt_type.duration_time.to_i
          item[:category] = appnt_type.category.nil? ? "Other" : appnt_type.category
          result[:appointment_types] << item
        end
      else
        appointment_types = @company.appointment_types.select("appointment_types.id , appointment_types.name , appointment_types.color_code , appointment_types.duration_time ")
        appointment_types.each do |appnt_type|
          item = {}
          item[:id] = appnt_type.id
          item[:name] = appnt_type.name
          item[:color_code] = appnt_type.color_code
          item[:duration_time] = appnt_type.duration_time.to_i
          result[:appointment_types] << item
        end
      end
    else
      result[:appointment_types] = []
      result[:default_appointment_type] = nil
      appointment_types = @company.appointment_types.select("appointment_types.id , appointment_types.name , appointment_types.color_code , appointment_types.duration_time ")
      appointment_types.each do |appnt_type|
        item = {}
        item[:id] = appnt_type.id
        item[:name] = appnt_type.name
        item[:color_code] = appnt_type.color_code
        item[:duration_time] = appnt_type.duration_time.to_i
        result[:appointment_types] << item
      end
    end
    render :json => result
  end

  def calendar_setting
    result = {}
    account = @company.account
    calendar_setting = account.calendar_setting
    result[:size] = calendar_setting["size"]
    result[:height] = calendar_setting["height"]
    result[:time_range] = calendar_setting["time_range"]
    result[:multi_appointment] = account.multi_appointment
    result[:show_time_indicator] = account.show_time_indicator

    render :json => result
  end

  def treatment_notes
    result = {}
    patient = Patient.find_by_id(params[:patient_id])

    if can? :view_all, TreatmentNote
      treatment_notes = patient.treatment_notes.active_treatment_note.order('created_at desc')
    else
      if can? :view_own, TreatmentNote
        treatment_notes = patient.treatment_notes.active_treatment_note.where(['created_by_id =? ', current_user.id]).order('created_at desc')
      else
        treatment_notes = []
      end
    end

    # Getting treatement note format
    result[:treatment_notes] = []
    treatment_note_view(treatment_notes, result)

    files = patient.file_attachments.order("created_at desc")
    result[:files] = []
    files.each do |attach_file|
      item = {}
      item[:id] = attach_file.id
      item[:name] = attach_file.avatar.original_filename
      item[:type] = attached_file_type(attach_file)
      item[:description] = attach_file.description.nil? ? "" : attach_file.description
      item[:created_on] = attach_file.created_at.strftime("%d %b %Y")
      item[:file_size] = number_to_human_size(attach_file.avatar.size)
      item[:file_url] = attach_file.avatar.to_s
      item[:created_by] = User.find(attach_file.created_by).full_name unless attach_file.created_by.nil?

      security_role_item = {}
      security_role_item[:upload] = can? :upload, FileAttachment
      security_role_item[:modify] = can? :edit, FileAttachment
      if can? :delall, FileAttachment
        security_role_item[:delete] = true
      else
        if can? :delown, FileAttachment
          security_role_item[:delete] = (attach_file.created_by.to_s == current_user.id.to_s)
        else
          security_role_item[:delete] = false
        end
      end

      security_role_item[:view_name] = can? :viewname, FileAttachment
      security_role_item[:clickable_link] = can? :viewfile, FileAttachment
      security_role_item[:role] = current_user.role
      item[:security_role] = security_role_item

      result[:files] << item
    end
    result[:file_upload] = can? :upload, FileAttachment
    render :json => result

  end

  def view_logs
    result = []
    unless @appointment.nil?
      appointment_activities = PublicActivity::Activity.where(trackable_id: @appointment.id, trackable_type: 'Appointment')
      appointment_activities.each do |obj|
        item = {}
        item[:created_at] = obj.created_at.strftime('%A, %d %B %Y at %H:%M%p')
        key = obj.key.split(".")[1]
        if (key =='Reschedule') || (key =='patient_status') || (key =='appnt_status')
          item[:creator] = (obj.trackable.try(:rescheduler).try(:full_name))
        elsif (key =="Cancel")
          item[:creator] = (obj.trackable.try(:canceller).try(:full_name))
        else
          item[:creator] = obj.owner.try(:full_name)
        end

        item[:obj_type] = obj.trackable_type
        item[:obj_id] = obj.trackable.try(:formatted_id)

        item[:action] = key
        item[:patient_id] = (obj.parameters[:patient_id].nil? ? obj.trackable.patient.try(:id) : obj.parameters[:patient_id])
        item[:patient_name] = (obj.parameters[:patient_name].nil? ? obj.trackable.patient.try(:full_name) : obj.parameters[:patient_name])
        item[:doctor_id] = (obj.parameters[:doctor_id].nil? ? obj.trackable.user.try(:id) : obj.parameters[:doctor_id])
        item[:doctor_name] = (obj.parameters[:doctor_name].nil? ? obj.trackable.user.try(:full_name) : obj.parameters[:doctor_name])
        item[:booking_time] = (obj.parameters[:booking_date].nil? ? obj.trackable.try(:date_and_time_without_name) : obj.parameters[:booking_date])

        item[:new_bk_str_time] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_str_time]
        item[:old_bk_str_time] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_str_time]

        item[:new_bk_end_time] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_end_time]
        item[:old_bk_end_time] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_end_time]

        item[:new_date] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_date]
        item[:old_date] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_date]

        item[:old_patient_status] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_patient_status]
        item[:new_patient_status] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_patient_status]

        item[:old_appnt_status] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:old_appnt_status]
        item[:new_appnt_status] = obj.parameters[:other].nil? ? nil : obj.parameters[:other][:new_appnt_status]
        item[:cancel_reason] = obj.parameters[:reason].nil? ? nil : obj.parameters[:reason]
        item[:service] = obj.trackable.try(:appointment_type).try(:name)


        item[:total_appnts] = (obj.parameters[:total_appnts].nil? ? 1 : obj.parameters[:total_appnts])
        item[:type_wise] = obj.parameters[:type_wise]

        result << item
      end

      render :json => {:logs => result}
    else
      item = {}
      item[:info] = "Appointment Not found"
      item[:status] = false
      render :json => item
    end

  end

  def get_template_notes
    result = {}
    result[:selected_note] = @appointment.try(:appointment_type).try(:template_note).try(:id)
    template_notes = @company.template_notes.order('created_at desc').select("id , name")
    result[:notes] = template_notes
    render :json => result
  end

  def check_security_role
    result ={}
    result[:view] = can? :index, Appointment
    result[:create] = can? :create, Appointment
    result[:modify] = can? :edit, Appointment
    result[:destroy] = can? :destroy, Appointment
    invoice_permsn = {}
    invoice_permsn[:view] = can? :index, Invoice
    invoice_permsn[:create] = can? :create, Invoice
    invoice_permsn[:modify] = can? :edit, Invoice
    invoice_permsn[:delete] = can? :destroy, Invoice
    invoice_permsn[:manage_payment] = can? :create, Payment
    result[:invoice_prmsn] = invoice_permsn
    payment_pmsn = {}
    payment_pmsn[:view] = can? :index, Payment
    payment_pmsn[:create] = can? :create, Payment
    payment_pmsn[:modify] = can? :update, Payment
    payment_pmsn[:delete] = can? :destroy, Payment
    result[:payment_pmsn] = payment_pmsn

    result[:managetr_note_add] = (can? :view_own, TreatmentNote)
    result[:managetr_note_view] = ((can? :view_own, TreatmentNote) || (can? :view_all, TreatmentNote) || (can? :edit_own, TreatmentNote) || (can? :delete, TreatmentNote))


    result[:file_tab] = (can? :upload, FileAttachment) || (can? :edit, FileAttachment) || (can? :delall, FileAttachment) || (can? :delown, FileAttachment) || (can? :viewname, FileAttachment) || (can? :viewfile, FileAttachment)


    result[:managetr_note_class_index] = check_tr_note_permission(result[:managetr_note_add], result[:managetr_note_view], result[:file_tab])

    render :json => result
  end

  def future_appnt_print
    @patient = @appointment.patient
    @future_appointments = @patient.appointments.where(["(Date(appnt_date) >= ? AND appnt_time_start  > CAST(?  AS time) AND status= ?) OR (Date(appnt_date) > ? AND status= ?) ", @appointment.appnt_date, @appointment.appnt_time_start, true, @appointment.appnt_date, true]).order("appnt_date asc")
    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => "pdf_name.pdf",
               :layout => '/layouts/pdf.html.erb',
               :disposition => 'inline',
               :template => "/appointments/future_appnt_print.pdf.erb",
               :show_as_html => false,
               :footer => {right: '[page] of [topage]'}

      end
    end

  end

  private

  def params_appointment
    params.require(:appointment).permit(:id, :user_id, :patient_id, :appnt_date, :appnt_time_start, :appnt_time_end, :repeat_by, :repeat_start, :repeat_end, :notes, :reason, :appnt_status, :patient_arrive,
                                        :appointment_types_appointment_attributes => [:appointment_type_id],
                                        :appointments_business_attributes => [:business_id],
                                        :wait_lists_appointment_attributes => [:wait_list_id]
    ).tap do |whitelisted|
      whitelisted[:week_days] = params[:appointment][:week_days]
      if action_name == "create_appnt_through_online_booking"
        whitelisted[:booker_type] = "Patient"
        whitelisted[:online_booked] = true
        whitelisted[:booker_id] = (params[:appointment][:patient_id])
      else
        whitelisted[:booker_type] = current_user.nil? ? "Patient" : "User"
        whitelisted[:booker_id] = current_user.nil? ? (params[:appointment][:patient_id]) : (current_user.id)
      end


      if action_name == "update_partially"
        whitelisted[:rescheduler_type] = "User"
        whitelisted[:rescheduler_id] = current_user.id
      elsif action_name == "update_partially_booking"
        whitelisted[:rescheduler_type] = "Patient"
        whitelisted[:rescheduler_id] = (params[:appointment][:patient_id])
      end
    end
  end

  def stop_activity
    Appointment.public_activity_off
  end

  def find_appointment
    @appointment = Appointment.where(["id = ?", params[:id]]).active_appointment.first
  end

  def random_key
    return rand(1000000)
  end

  def convert_into_time(t1, t2)
    return t1.to_i + (t2.to_i / 60.0)
  end

  def create_appointment_manually(params_appointment, business)
    appointment = @company.appointments.new(params_appointment)
    if appointment.valid?
      appointment.unique_key = random_key
      appointment.business = business
      appointment.with_lock do
        appointment.save
      end
      return true
    else
      return false
    end
  end

  def occurrence_parameters_same(appnt, param_appointment)
    if param_appointment[:repeat_by].nil?
      param_appointment[:repeat_by] = appnt.repeat_by
      param_appointment[:repeat_start] = appnt.repeat_start
      param_appointment[:repeat_end] = appnt.repeat_end
    end
    return param_appointment

    
  end

  #   filter method to change params in structured format
  def set_params_in_standard_format
    unless params[:appointment].nil?
      structure_format = {}
      structure_format[:id] = params[:appointment][:id] unless params[:appointment][:id].nil?
      structure_format[:appnt_date] = params[:appointment][:appnt_date] unless params[:appointment][:appnt_date].nil?
      start_hr = (params[:appointment][:start_hr].nil? || params[:appointment][:start_hr].blank?) ? "0" : params[:appointment][:start_hr]
      start_min = (params[:appointment][:start_min].nil? || params[:appointment][:start_min].blank?) ? "0" : params[:appointment][:start_min]
      start_time = start_hr.to_s + ":" + start_min.to_s

      end_hr = (params[:appointment][:end_hr].nil? || params[:appointment][:end_hr].blank?) ? "0" : params[:appointment][:end_hr]
      end_min = (params[:appointment][:end_min].nil? || params[:appointment][:end_min].blank?) ? "0" : params[:appointment][:end_min]
      end_time = end_hr.to_s + ":"+ end_min.to_s

      structure_format[:appnt_time_start] = start_time unless start_time == "0:0"
      structure_format[:appnt_time_end] = end_time unless end_time == "0:0"
      structure_format[:repeat_by] = params[:appointment][:repeat_by] unless params[:appointment][:repeat_by].nil?
      structure_format[:repeat_start] = params[:appointment][:repeat_start] unless params[:appointment][:repeat_start].nil?
      structure_format[:repeat_end] = params[:appointment][:repeat_end] unless params[:appointment][:repeat_end].nil?
      structure_format[:user_id] = params[:appointment][:user_id] unless params[:appointment][:user_id].nil?
      structure_format[:notes] = params[:appointment][:notes] unless params[:appointment][:notes].nil?
      structure_format[:flag] = params[:appointment][:flag] unless params[:appointment][:flag].nil?
      structure_format[:reason] = params[:appointment][:reason] unless params[:appointment][:reason].nil?
      structure_format[:patient_arrive] = params[:appointment][:patient_arrive] if params[:appointment].has_key? "patient_arrive"

      if params[:appointment].has_key? "appnt_status"
        structure_format[:appnt_status] = params[:appointment][:appnt_status]
        if params[:appointment][:appnt_status] == true
          structure_format[:patient_arrive] = true
        end
      end
      if params[:appointment][:repeat_by] == "week"
        unless params[:appointment][:week_days].nil?
          structure_format[:week_days] = params[:appointment][:week_days]
        else
          structure_format[:week_days] = []
          appnt = Appointment.new
          appnt.errors.add(:week_day, "must be selected at least one.")
          show_error_json(appnt.errors.messages)
          return false
        end
      else
        structure_format[:week_days] = []
      end

#     when a new patient is created at appointment booking time
      unless params[:appointment][:patient_id].nil?
        structure_format[:patient_id] = params[:appointment][:patient_id]
      else
        unless params[:appointment][:new_patient].blank? || params[:appointment][:new_patient].nil?
          @company = Company.find_by_id(params[:comp_id]) if params[:comp_id].present?
          @business = Business.find_by_id(params[:appointment][:business_id]) if params[:appointment][:business_id].present?
          @company = Company.find_by_id(@business.company_id)
          patient = @company.patients.where(first_name: params[:appointment][:new_patient][:first_name], last_name: params[:appointment][:new_patient][:last_name], email: params[:appointment][:new_patient][:email], status: 'active').first_or_initialize(title: params[:appointment][:new_patient][:title], first_name: params[:appointment][:new_patient][:first_name], last_name: params[:appointment][:new_patient][:last_name], dob: params[:appointment][:new_patient][:dob], email: params[:appointment][:new_patient][:email], reminder_type: params[:appointment][:new_patient][:reminder_type], gender: params[:appointment][:new_patient][:gender], address: params[:appointment][:new_patient][:address], city: @business.city, state: @business.state, country: @business.country, postal_code: @business.pin_code, referral_type: params[:appointment][:new_patient][:referral_type], referrer: params[:appointment][:new_patient][:referrer], extra_info: params[:appointment][:new_patient][:extra_info], profile_pic: params[:appointment][:new_patient][:profile_pic], reference_number: params[:appointment][:new_patient][:reference_number])
          if patient.new_record?
            patient.patient_contacts.build(contact_no: params[:appointment][:new_patient][:contact_no], contact_type: 'mobile') unless ((params[:appointment][:new_patient][:contact_no].nil?))
            if patient.valid?
              patient.with_lock do
                patient.token = SecureRandom.base64 if params[:appointment][:new_patient]['remember_me']
                patient.save
              end
              structure_format[:patient_id] = patient.id
            else
              show_error_json(patient.errors.messages)
              return false
            end
          else
            avail_pic = params[:appointment][:new_patient][:profile_pic] rescue nil
            # Adding new contact in patient contacts if contacts not available
            unless ((params[:appointment][:new_patient][:contact_no].nil?) & (params[:appointment][:new_patient][:contact_type].nil?))
              number_exist = false
              patient.patient_contacts.map(&:contact_no).each { |k| number_exist = true if (k.include?(params[:appointment][:new_patient][:contact_no])) }
              patient.patient_contacts.create(contact_no: params[:appointment][:new_patient][:contact_no], contact_type: params[:appointment][:new_patient][:contact_type]) unless number_exist
            end
            patient.update(profile_pic: avail_pic) unless avail_pic.nil?
            if params[:appointment][:new_patient]['remember_me'] == true
              patient.update(token: SecureRandom.base64)
            else
              patient.update(token: nil)
            end
            patient.update(dob: params[:appointment][:new_patient][:dob].try(:to_date)) unless params[:appointment][:new_patient][:dob].nil?
            structure_format[:patient_id] = patient.id
          end
        end
      end

#     passing appointment type strong parameter with appointment

      unless params[:appointment][:appointment_type_id].nil?
        appointment_type_item = {}
        appointment_type_item[:appointment_type_id] = params[:appointment][:appointment_type_id]
        structure_format[:appointment_types_appointment_attributes] = appointment_type_item
      end
#     passing business strong parameter with appointment only when appointment is created
      if action_name == "create" || action_name == "create_appnt_through_online_booking"
        business_item = {}
        business_item[:business_id] = params[:appointment][:business_id]
        structure_format[:appointments_business_attributes] = business_item
      end
#     when wait_list is available with appointment
      if action_name == "create"
        unless params[:appointment][:existing_wait_list].nil?
          wait_list = WaitList.find_by_id(params[:appointment][:existing_wait_list])
          unless wait_list.nil?
            wait_list.update_attributes(status: false)
          end
        end
        if params[:appointment][:associated_appointment].present? && params[:appointment][:associated_appointment_checked] == true
          previous_appnt = Appointment.find_by_id(params[:appointment][:associated_appointment])
          unless previous_appnt.nil?
            previous_appnt.update_attributes(:status => false)
          end
        end
        unless params[:appointment][:wait_list].nil?
          unless params[:appointment][:appnt_date].to_date <= Date.today

            # verifying weather patient has already wait list or not
            unless patient_has_active_wait_list(structure_format[:patient_id])

              business_lists = []
              params[:appointment][:wait_list][:businesses].each do |business|
                if business[:is_selected]
                  business_lists << {:business_id => business[:business_id]}
                end
              end unless params[:appointment][:wait_list][:businesses].nil?

              practitioners_list = []
              params[:appointment][:wait_list][:practitioners].each do |doctor|
                if doctor[:is_selected]
                  practitioners_list << {:user_id => doctor[:practitioner_id]}
                end
              end unless params[:appointment][:wait_list][:practitioners].nil?

              wait_list = @company.wait_lists.new(:options => params[:appointment][:wait_list][:options], :availability => params[:appointment][:wait_list][:availability], :extra_info => params[:appointment][:wait_list][:extra_info],
                                                  :wait_lists_patient_attributes => {:patient_id => structure_format[:patient_id]},
                                                  :appointment_types_wait_list_attributes => {:appointment_type_id => appointment_type_item[:appointment_type_id]},
                                                  :wait_lists_businesses_attributes => business_lists,
                                                  :wait_lists_users_attributes => practitioners_list)
              if wait_list.valid?
                wait_list.with_lock do
                  wait_list.save
                end
              else
                show_error_json(wait_list.errors.messages)
                return false
              end
            else
              wait_list = WaitList.new
              patient = Patient.find_by_id(structure_format[:patient_id])
              if patient.nil?
                wait_list.errors.add(:patient, "is already on wait list")
              else
                wait_list.errors.add("#{patient.full_name_without_title}", "is already on wait list")
              end
              show_error_json(wait_list.errors.messages)
              return false
            end
            #       till here

            #       passing wait_list strong parameter with appointment
            wait_list_item = {}
            wait_list_item[:wait_list_id] = wait_list.id
            structure_format[:wait_lists_appointment_attributes] = wait_list_item
          else
            structure_format[:wait_lists_appointment_attributes] = "500"
          end
        end
      end


    else
      structure_format = {}
    end
    params[:appointment] = structure_format
  end

  def patient_has_active_wait_list(patient_id, wait_list = nil)
    patient = Patient.find_by_id(patient_id)
    result = false
    if wait_list.nil?
      unless patient.nil?
        if patient.wait_list.try(:status) == true
          result = true
        end
      end
    else
      if wait_list.patient.id == patient_id
        result = true
      end
    end

    return result
  end

  def invoices_paid_or_unpaid(flag, invoices)
    invoices_ids = []
    if flag == true
      invoices.each do |invoice|
        if invoice.calculate_outstanding_balance == 0
          invoices_ids << invoice.id
        end
      end
    else
      invoices.each do |invoice|
        if invoice.calculate_outstanding_balance > 0
          invoices_ids << invoice.id
        end
      end
    end
    return invoices_ids
  end

  def filteration_appointments(patient_arrive_filter, invoice_filter, treatment_note_filter, appointment_complete_filter, patient_future_appointment, invoice_ids = [], doctors_id, business_id, start_date, end_date)
    appointments = []
    if patient_arrive_filter.nil? && invoice_filter.nil? && treatment_note_filter.nil? && appointment_complete_filter.nil? && patient_future_appointment.nil?

      appointments = Appointment.joins(:patient, :business).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", "active", doctors_id, business_id, start_date, end_date])

    elsif !(patient_arrive_filter.nil?) && invoice_filter.nil? && treatment_note_filter.nil? && appointment_complete_filter.nil? && patient_future_appointment.nil?
      appointments = Appointment.joins(:patient, :business).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.patient_arrive = ? ", "active", doctors_id, business_id, start_date, end_date, patient_arrive_filter])

    elsif patient_arrive_filter.nil? && !(invoice_filter.nil?) && treatment_note_filter.nil? && appointment_complete_filter.nil? && patient_future_appointment.nil?
      if invoice_ids.length > 0
        appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.status = ? AND invoices.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", "active", invoice_ids, doctors_id, business_id, start_date, end_date])
      else
        appointments = Appointment.joins(:patient, :business).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", "active", doctors_id, business_id, start_date, end_date])
      end

    elsif patient_arrive_filter.nil? && invoice_filter.nil? && !(treatment_note_filter.nil?) && appointment_complete_filter.nil? && patient_future_appointment.nil?
      appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.status = ? AND treatment_notes.save_final= ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", "active", treatment_note_filter, doctors_id, business_id, start_date, end_date])

    elsif patient_arrive_filter.nil? && invoice_filter.nil? && treatment_note_filter.nil? && !(appointment_complete_filter.nil?) && patient_future_appointment.nil?
      appointments = Appointment.joins(:patient, :business).where(["patients.status = ? AND appointments.appnt_status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", "active", appointment_complete_filter, doctors_id, business_id, start_date, end_date])

    elsif patient_arrive_filter.nil? && invoice_filter.nil? && treatment_note_filter.nil? && appointment_complete_filter.nil? && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if patient_future_appointment == true
        appointments = @company.appointments.joins(:patient, :business).where(["patients.id IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", future_patients_ids, doctors_id, business_id, start_date, end_date])
      else
        appointments = @company.appointments.joins(:patient, :business).where(["patients.id NOT IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)", future_patients_ids, doctors_id, business_id, start_date, end_date])

      end
    elsif patient_arrive_filter.nil? && invoice_filter.nil? && treatment_note_filter.nil? && !(appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if patient_future_appointment == true

        appointments = @company.appointments.joins(:patient, :business).where(["patients.id IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter])
      else
        appointments = @company.appointments.joins(:patient, :business).where(["patients.id NOT IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter])
      end


    elsif patient_arrive_filter.nil? && invoice_filter.nil? && !(treatment_note_filter.nil?) && appointment_complete_filter.nil? && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if patient_future_appointment == true
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter])
      else
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id NOT IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter])
      end


    elsif patient_arrive_filter.nil? && !(invoice_filter.nil?) && treatment_note_filter.nil? && appointment_complete_filter.nil? && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if invoice_ids.length > 0
        if patient_future_appointment == true

          appointments = Appointment.joins(:business, :patient => [:invoices]).where([" patients.id IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND invoices.id IN (?) ", future_patients_ids, doctors_id, business_id, start_date, end_date, invoice_ids])
        else
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND invoices.id IN (?) ", future_patients_ids, doctors_id, business_id, start_date, end_date, invoice_ids])
        end
      else
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) ", future_patients_ids, doctors_id, business_id, start_date, end_date])
        else
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id NOT IN  (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) ", future_patients_ids, doctors_id, business_id, start_date, end_date])
        end

      end

    elsif !(patient_arrive_filter.nil?) && invoice_filter.nil? && treatment_note_filter.nil? && appointment_complete_filter.nil? && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids

      if patient_future_appointment == true
        appointments = Appointment.joins(:patient, :business).where(["patients.id IN (?)  AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.patient_arrive = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter])
      else
        appointments = Appointment.joins(:patient, :business).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.patient_arrive = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter])
      end


    elsif patient_arrive_filter.nil? && invoice_filter.nil? && !(treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && patient_future_appointment.nil?
      appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status =?", "active", doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter])

    elsif patient_arrive_filter.nil? && !(invoice_filter.nil?) && treatment_note_filter.nil? && !(appointment_complete_filter.nil?) && patient_future_appointment.nil?
      if invoice_ids.length > 0
        appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)AND invoices.id IN (?) AND appointments.appnt_status = ?", "active", doctors_id, business_id, start_date, end_date, invoice_ids, appointment_complete_filter])
      else
        appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ?", "active", doctors_id, business_id, start_date, end_date, appointment_complete_filter])
      end

    elsif !(patient_arrive_filter.nil?) && invoice_filter.nil? && treatment_note_filter.nil? && !(appointment_complete_filter.nil?) && patient_future_appointment.nil?
      appointments = Appointment.joins(:patient, :business).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? AND appointments.patient_arrive = ? ", "active", doctors_id, business_id, start_date, end_date, appointment_complete_filter, patient_arrive_filter])

    elsif patient_arrive_filter.nil? && !(invoice_filter.nil?) && !(treatment_note_filter.nil?) && appointment_complete_filter.nil? && patient_future_appointment.nil?
      if invoice_ids.length > 0
        appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)AND invoices.id IN (?) AND treatment_notes.save_final  = ?", "active", doctors_id, business_id, start_date, end_date, invoice_ids, treatment_note_filter])
      else
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final  = ?", "active", doctors_id, business_id, start_date, end_date, treatment_note_filter])
      end

    elsif !(patient_arrive_filter.nil?) && invoice_filter.nil? && !(treatment_note_filter.nil?) && appointment_complete_filter.nil? && patient_future_appointment.nil?
      appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final  = ? AND appointments.patient_arrive = ?", "active", doctors_id, business_id, start_date, end_date, treatment_note_filter, patient_arrive_filter])

    elsif patient_arrive_filter.nil? && invoice_filter.nil? && !(treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if patient_future_appointment == true
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? AND treatment_notes.save_final = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter, treatment_note_filter])
      else
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id Not IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? AND treatment_notes.save_final = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter, treatment_note_filter])
      end


    elsif patient_arrive_filter.nil? && !(invoice_filter.nil?) && treatment_note_filter.nil? && !(appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)

      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids

      if invoice_ids.length > 0
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? AND invoices.id IN  (?) ", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter, invoice_ids])
        else
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? AND invoices.id IN  (?) ", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter, invoice_ids])
        end

      else
        if patient_future_appointment == true
          appointments = Appointment.joins(:patient, :business).where(["patients.id IN (?) AND Date appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter])
        else
          appointments = Appointment.joins(:patient, :business).where(["patients.id NOT IN (?) AND Date appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter])
        end

      end

    elsif !(patient_arrive_filter.nil?) && invoice_filter.nil? && treatment_note_filter.nil? && !(appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if patient_future_appointment == true
        appointments = Appointment.joins(:patient, :business).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? AND appointments.patient_arrive = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter, patient_arrive_filter])
      else
        appointments = Appointment.joins(:patient, :business).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND appointments.appnt_status = ? AND appointments.patient_arrive = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, appointment_complete_filter, patient_arrive_filter])
      end


    elsif patient_arrive_filter.nil? && !(invoice_filter.nil?) && !(treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids

      if invoice_ids.length > 0
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND invoices.id IN (?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, invoice_ids, treatment_note_filter, appointment_complete_filter])
        else
          appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND invoices.id IN (?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, invoice_ids, treatment_note_filter, appointment_complete_filter])
        end
      else
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter])
        else
          appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id NOT IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter])
        end
      end

    elsif !(patient_arrive_filter.nil?) && invoice_filter.nil? && !(treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if patient_future_appointment == true
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter])
      else
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter])
      end


    elsif !(patient_arrive_filter.nil?) && !(invoice_filter.nil?) && !(treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids

      if invoice_ids.length > 0
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, patient => [:invoices, :treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ? AND invoices.id IN (?)", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter, invoice_ids])
        else
          appointments = Appointment.joins(:business, patient => [:invoices, :treatment_notes]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ? AND invoices.id IN (?)", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter, invoice_ids])
        end

      else
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter])
        else
          appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter])
        end
      end

    elsif (patient_arrive_filter.nil?) && !(invoice_filter.nil?) && !(treatment_note_filter.nil?) && (appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids

      if invoice_ids.length > 0
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND invoices.id IN (?)", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, invoice_ids])
        else
          appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND invoices.id IN (?)", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, invoice_ids])
        end

      else
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter])
        else
          appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter])
        end
      end

    elsif (patient_arrive_filter.nil?) && !(invoice_filter.nil?) && !(treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && (patient_future_appointment.nil?)
      if invoice_ids.length > 0
        appointments = Appointment.joins(:business, :pateint => [:invoices, :treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND invoices.id IN (?)", "active", doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, invoice_ids])
      else
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? ", "active", doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter])
      end

    elsif !(patient_arrive_filter.nil?) && (invoice_filter.nil?) && !(treatment_note_filter.nil?) && (appointment_complete_filter.nil?) &&
        future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids

      if patient_future_appointment == true
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.patient_arrive = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, patient_arrive_filter])
      else
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.patient_arrive = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, treatment_note_filter, patient_arrive_filter])
      end


    elsif !(patient_arrive_filter.nil?) && (invoice_filter.nil?) && !(treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && (patient_future_appointment.nil?)
      appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ? ", "active", doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter])

    elsif !(patient_arrive_filter.nil?) && !(invoice_filter.nil?) && (treatment_note_filter.nil?) && (appointment_complete_filter.nil?) && (patient_future_appointment.nil?)
      if invoice_ids.length > 0
        appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?)", "active", doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids])
      else
        appointments = Appointment.joins(:patient, :business).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ?", "active", doctors_id, business_id, start_date, end_date, patient_arrive_filter])
      end

    elsif !(patient_arrive_filter.nil?) && !(invoice_filter.nil?) && (treatment_note_filter.nil?) && (appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids

      if invoice_ids.length > 0
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?)", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids])
        else
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?)", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids])
        end
      else
        if patient_future_appointment == true
          appointments = Appointment.joins(:patient, :business).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter])
        else
          appointments = Appointment.joins(:patient, :business).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? ", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter])
        end

      end

    elsif !(patient_arrive_filter.nil?) && !(invoice_filter.nil?) && (treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && (patient_future_appointment.nil?)
      if invoice_ids.length > 0
        appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?) AND appointments.appnt_status = ?", "active", doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids, appointment_complete_filter])
      else
        appointments = Appointment.joins(:patient, :business).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND appointments.appnt_status = ?", "active", doctors_id, business_id, start_date, end_date, patient_arrive_filter, appointment_complete_filter])
      end

    elsif !(patient_arrive_filter.nil?) && !(invoice_filter.nil?) && (treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if invoice_ids.length > 0
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?) AND appointment.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids, appointment_complete_filter])
        else
          appointments = Appointment.joins(:business, :patient => [:invoices]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?) AND appointment.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids, appointment_complete_filter])
        end

      else
        if patient_future_appointment == true
          appointments = Appointment.joins(:patient, :business).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND appointment.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, appointment_complete_filter])
        else
          appointments = Appointment.joins(:patient, :business).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND appointment.appnt_status = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, appointment_complete_filter])
        end

      end

    elsif !(patient_arrive_filter.nil?) && !(invoice_filter.nil?) && !(treatment_note_filter.nil?) && (appointment_complete_filter.nil?) && (patient_future_appointment.nil?)
      if invoice_ids.length > 0
        appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?) AND treatment_notes.save_final =?", "active", doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids, treatment_note_filter])
      else
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND treatment_notes.save_final =?", "active", doctors_id, business_id, start_date, end_date, patient_arrive_filter, treatment_note_filter])
      end

    elsif !(patient_arrive_filter.nil?) && !(invoice_filter.nil?) && !(treatment_note_filter.nil?) && (appointment_complete_filter.nil?) && !(patient_future_appointment.nil?)
      future_patients_ids = @company.patients.joins(:appointments => [:user, :business]).where(["patients.status = ? AND Date(appnt_date) > ? AND appointments.user_id IN (?) AND businesses.id = ?", "active", Date.today, doctors_id, business_id]).ids
      if invoice_ids.length > 0
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where([" patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?) AND treatment_notes.save_final = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids, treatment_note_filter])
        else
          appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where([" patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND invoices.id IN (?) AND treatment_notes.save_final = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, invoice_ids, treatment_note_filter])
        end
      else
        if patient_future_appointment == true
          appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND treatment_notes.save_final = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, treatment_note_filter])
        else
          appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.id NOT IN (?) AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?)  AND appointments.patient_arrive = ? AND treatment_notes.save_final = ?", future_patients_ids, doctors_id, business_id, start_date, end_date, patient_arrive_filter, treatment_note_filter])
        end
      end

    elsif !(patient_arrive_filter.nil?) && !(invoice_filter.nil?) && !(treatment_note_filter.nil?) && !(appointment_complete_filter.nil?) && (patient_future_appointment.nil?)
      if invoice_ids.length > 0
        appointments = Appointment.joins(:business, :patient => [:invoices, :treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ? AND invoices.id IN (?)", "active", doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter, invoice_ids])
      else
        appointments = Appointment.joins(:business, :patient => [:treatment_notes]).where(["patients.status = ? AND appointments.user_id IN (?) AND businesses.id = ? AND (DATE(appnt_date) >= ? AND DATE(appnt_date) <= ?) AND treatment_notes.save_final = ? AND appointments.appnt_status = ? AND appointments.patient_arrive = ?", "active", doctors_id, business_id, start_date, end_date, treatment_note_filter, appointment_complete_filter, patient_arrive_filter])
      end
    end


    return appointments.uniq

  end

  # checking is a time existing in a time duration
  def time_exist_in_time_range(time, arr_element)
    if action_name == "check_practitioner_availability_for_specific_day_and_time_on_a_location"
      allowed_ranges = (arr_element[0].to_s)..(arr_element[1].to_s)
    else
      allowed_ranges = arr_element
    end
    formatted_time = time.to_datetime.strftime("%H:%M")
    flag = ([] << allowed_ranges).any? { |range| range.cover?(formatted_time) }
    return flag
  end


  def replace_existing_time_slot_in_out_service_time(day_name, start_time, end_time, out_of_service_slots)
    out_of_service_slots.each do |slot|
      if slot[:day].casecmp(day_name) == 0

        arr_time_slots = slot[:time_range]
        arr_time_slots.each do |tm_elem|
          new_elements = []
          tm_range = convert_into_range(tm_elem[:start_time], tm_elem[:end_time])
          if time_exist_in_time_range(start_time, tm_range)
            unless (start_time.to_datetime.strftime("%H:%M")==convert_into_time_format(tm_elem[:start_time]))
              unless is_time_small(start_time, tm_elem[:start_time])
                item = {}
                item[:start_time] = tm_elem[:start_time]
                item[:end_time] = start_time.to_datetime.strftime("%H:%M")
                new_elements << item
              end
            end
          end

          if time_exist_in_time_range(end_time, tm_range)
            unless (end_time.to_datetime.strftime("%H:%M") == convert_into_time_format(tm_elem[:end_time]))
              if is_time_small(end_time, tm_elem[:end_time])
                item = {}
                item[:start_time] = end_time.to_datetime.strftime("%H:%M")
                item[:end_time] = tm_elem[:end_time]
                new_elements << item
              end
            end

          end
          if new_elements.length > 0
            slot[:time_range].map! { |x| x == tm_elem ? new_elements : x }.flatten!
          end
        end

      end
    end
  end

  def is_time_small(t1, t2)
    first_time = t1.to_datetime.strftime("%H").to_i + (t1.to_datetime.strftime("%M").to_i/60.0)
    second_time = t2.split(":")[0].to_i + t2.split(":")[1].to_i/60.0
    return first_time < second_time
  end

  def convert_into_range(t1, t2)
    a = t1.split(":")
    st_time = (a[0].length == 2 ? a[0] : "0#{a[0]}") + ":" + (a[1].length == 2 ? a[1] : "0#{a[1]}")
    b = t2.split(":")
    end_time = (b[0].length == 2 ? b[0] : "0#{b[0]}")+ ":" + (b[1].length == 2 ? b[1] : "0#{b[1]}")

    return (st_time..end_time)
  end

  def convert_into_time_format(time)
    a = time.split(":")
    st_time = (a[0].length == 2 ? a[0] : "0#{a[0]}") + ":" + (a[1].length == 2 ? a[1] : "0#{a[1]}")
    return st_time
  end

  def get_logs_in_format(apnt_log)
    item = {}
    item[:creator_name] = apnt_log.user.full_name
    item[:updated_at] = apnt_log.audited_changes["updated_at"][1].strftime("%d %B %Y,%l:%M%p") unless apnt_log.audited_changes["updated_at"].nil?
    apnt_log.audited_changes.delete("updated_at")
    if apnt_log.audited_changes.has_key? "patient_id"
      apnt_log.audited_changes = replace_patient_ids_with_names(apnt_log.audited_changes)
    end

    if apnt_log.audited_changes.has_key? "user_id"
      apnt_log.audited_changes = replace_user_ids_with_names(apnt_log.audited_changes)
    end
    item[:audited_changes] = apnt_log.audited_changes
    return item
  end

  def replace_patient_ids_with_names(audited_changes)
    patient_ids = audited_changes["patient_id"]
    old_patient = Patient.find_by_id(patient_ids.first).try(:full_name_without_title)
    new_patient = Patient.find_by_id(patient_ids.second).try(:full_name_without_title)
    audited_changes["patient_id"] = [old_patient, new_patient]
    return audited_changes
  end

  def replace_user_ids_with_names(audited_changes)
    user_ids = audited_changes["user_id"]
    previous_doctor = User.find_by_id(user_ids.first).try(:full_name)
    new_doctor = User.find_by_id(user_ids.second).try(:full_name)
    audited_changes["user_id"] = [previous_doctor, new_doctor]
    return audited_changes
  end


  # function for practitioner availability
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

  def change_time_into_decimal_number(st_hr, st_min)
    time = st_hr.to_f + ((st_min.to_f)/60.0)
  end

  # method to change a decimal number into time
  def convert_decimal_number_into_time(num)
    arr = (num.to_s).split(".")
    hr_elem = (arr[0].length == 1 ? ("0"+ arr[0]) : arr[0])
    min_elem = (((arr[1].length == 1 ? arr[1]+"0" : arr[1]).to_i)*60/100).to_s
    time = hr_elem +":"+ (min_elem.length == 1 ? ("0"+ min_elem) : min_elem)
    return time
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
      flag = false
      time_slots.each do |slot|
        if ((time_exist_in_time_range(appnt_slot[0], slot) && appnt_slot[0] != slot[1]) || (time_exist_in_time_range(appnt_slot[1], slot) && appnt_slot[1] != slot[0]))
          flag = true
        end
      end
      if flag == false
        result << appnt_slot
      end
    end
    return appnt_time_slots - result
  end

  def check_existance_of_time_into_time_range(start_time, end_time, time_slots)
    flag = true
    ctr = 0
    time_slots.each do |slot|
      if time_exist_in_time_range(start_time, slot)|| time_exist_in_time_range(end_time, slot)
        unless time_exist_in_time_range(start_time, slot) && time_exist_in_time_range(end_time, slot)
          break
        else
          ctr = 1
        end
      end
    end
    if ctr == 0
      flag = false
    end

    return flag
  end

  # It is calling when appointments are deleted during update process

  def create_activity_log(patient_id)
    patient = Patient.find_by_id(patient_id)
    unless patient.nil?
      last_appnt = patient.appointments.last
      Appointment.public_activity_on
      if last_appnt.has_series
        parent_appnt = last_appnt.inverse_childappointment
        appnt_type = parent_appnt.repeat_by
        # parent_appnt.create_activity :create , parameters: { content: parent_appnt.accurate_activity_log_text_create }

        parent_appnt.create_activity :create, parameters: {total_appnts: parent_appnt.series_length, type_wise: nil, patient_id: parent_appnt.patient.try(:id), patient_name: parent_appnt.patient.try(:full_name), doctor_id: parent_appnt.user.try(:id), doctor_name: parent_appnt.user.try(:full_name), booking_date: parent_appnt.date_and_time_without_name}
        parent_appnt.childappointments.each do |child_appnt|
          child_appnt.create_activity :create, parameters: {total_appnts: child_appnt.following_series_length, type_wise: nil, patient_id: child_appnt.patient.try(:id), patient_name: child_appnt.patient.try(:full_name), doctor_id: child_appnt.user.try(:id), doctor_name: child_appnt.user.try(:full_name), booking_date: child_appnt.date_and_time_without_name}
        end
      else
        appnt_type = last_appnt.repeat_by
        last_appnt.create_activity :create, parameters: {total_appnts: last_appnt.series_length, type_wise: nil, patient_id: last_appnt.patient.try(:id), patient_name: last_appnt.patient.try(:full_name), doctor_id: last_appnt.user.try(:id), doctor_name: last_appnt.user.try(:full_name), booking_date: last_appnt.date_and_time_without_name}
      end
    end
  end

  # It is calling when appointments are updated in a series

  def update_activity_log(patient_id)
    patient = Patient.find_by_id(patient_id)
    unless patient.nil?
      last_appnt = patient.appointments.last
      Appointment.public_activity_on
      if last_appnt.has_series
        parent_appnt = last_appnt.inverse_childappointment
        create_all_types_logs(parent_appnt, true)
      else
        create_all_types_logs(last_appnt, true)
      end
    end
  end

  def check_valid_patient
    @valid_patient = @company.patients.active_patient.ids.include?(params[:appointment][:patient_id])
  end


  def check_tr_note_permission(first_tab, second_tab, third_tab)
    index_no = 0
    if (first_tab == true && second_tab == true && third_tab)
      index_no = 4
    elsif (first_tab == true && second_tab == true && third_tab == false)
      index_no = 6
    elsif (first_tab == true && second_tab == false && third_tab)
      index_no = 6
    elsif (first_tab == true && second_tab == false && third_tab == false)
      index_no = 12
    elsif (first_tab == false && second_tab == true && third_tab)
      index_no = 6
    elsif (first_tab == false && second_tab == true && third_tab == false)
      index_no = 12
    elsif (first_tab == false && second_tab == false && third_tab)
      index_no = 12
    elsif (first_tab == false && second_tab == false && third_tab == false)
      index_no = 0
    end
    return index_no
  end

  def create_all_types_logs(appnt, flag=true)
    if appnt.audits.last.audited_changes.keys.include?('appnt_status')


      appnt.create_activity :appnt_status, parameters: {total_appnts: (flag ? (appnt.series_length) : 1), type_wise: nil, patient_id: appnt.patient.try(:id), patient_name: appnt.patient.try(:full_name), doctor_id: appnt.user.try(:id), doctor_name: appnt.user.try(:full_name), booking_date: appnt.date_and_time_without_name, other: appnt.accurate_activity_log_text_appnt_status}

    elsif appnt.audits.last.audited_changes.keys.include?('patient_arrive')


      appnt.create_activity :patient_status, parameters: {total_appnts: (flag ? appnt.series_length : 1), type_wise: nil, patient_id: appnt.patient.try(:id), patient_name: appnt.patient.try(:full_name), doctor_id: appnt.user.try(:id), doctor_name: appnt.user.try(:full_name), booking_date: appnt.date_and_time_without_name, other: appnt.accurate_activity_log_text_patient_status}

    else

      appnt.create_activity :Reschedule, parameters: {total_appnts: (flag ? appnt.series_length : 1), type_wise: nil, patient_id: appnt.patient.try(:id), patient_name: appnt.patient.try(:full_name), doctor_id: appnt.user.try(:id), doctor_name: appnt.user.try(:full_name), booking_date: appnt.date_and_time_without_name, other: appnt.accurate_activity_log_text_reschedule}

    end
  end

end
