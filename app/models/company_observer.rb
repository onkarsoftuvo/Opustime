class CompanyObserver < ActiveRecord::Observer
  observe :company

  def after_create(company)
    business = company.businesses.create(:name => company.company_name, :business_type => BUSINESS_TYPE[1], online_booking: false)
    company.users.map { |user| user.destroy }
    user = company.users.create(email: company.email, first_name: "@@@", last_name: "&&", :password => company.password, :password_confirmation => company.password, :role => ROLE[5], :is_doctor => true)
    user.update_columns(:combine_ids => "#{company.id}-#{user.id}")

    user_info = user.create_practi_info()

    user_info.businesses << business
    user_refer = user_info.practi_refers.create(business_id: business.id)
#   To create choice options for patient page  
    user.create_client_filter_choice(appointment: true, treatment_note: true, invoice: true, payment: true, attached_file: true, letter: true, communication: true, recall: true)
#     create online booking for company
    company.create_online_booking(min_appointment: "1", advance_booking_time: "1h", min_cancel_appoint_time: "1h", notify_by: "None")

#     create concession types
    CONCESSION_NAMES.each do |cs_name|
      company.concessions.create(:name => cs_name)
    end


# To create default taxes      
    TAXES.each do |tax|
      company.tax_settings.create(:name => tax, :amount => 10)
    end

# To create default payment types    
    PAYMENT_TYPES.each do |payment_name|
      company.payment_types.create(:name => payment_name)
    end

#     To create billable items and their concessions and amounts
    BILLABLE_ITEM_NAMES.each_with_index do |bill_item, index|
      if index==0
        billable_item = company.billable_items.create(:name => bill_item, :price => 100, :include_tax => false, :tax => "N/A")
      elsif index ==1
        billable_item = company.billable_items.create(:name => bill_item, :price => 50, :include_tax => false, :tax => "N/A")
      end
      billable_item.concession_price = []
      company.concessions.each do |concession|
        item_wise_concession = BillableItemsConcession.new(billable_item_id: billable_item.id, concession_id: concession.id, value: 0, name: concession.name)
        if item_wise_concession.valid?
          item_wise_concession.save
          billable_item.concession_price << {id: concession.id, name: concession.name, amount: ""}
        end

      end
      billable_item.save

    end

#     To create the template notes 
    TEMPLATE_NOTES_NAMES.each do |note_name|
      note = company.template_notes.create(:name => note_name)
      note_section = note.temp_sections.create()
      if note.name.casecmp(TEMPLATE_NOTES_NAMES[0]) == 0
        INITIAL_TREATMENT_NOTE_QUESTIONS.each do |quest|
          temp_question = note_section.questions.new(title: quest, q_type: "Paragraph")
          if temp_question.valid?
            if temp_question.save
              temp_question.quest_choices.create(:title => "")
              puts "#{quest} has been addded in company -#{company.full_name}"
            end
          end
        end
      elsif note.name.casecmp(TEMPLATE_NOTES_NAMES[1]) == 0
        STANDARD_TREATMENT_NOTE_QUESTIONS.each do |quest|
          temp_question = note_section.questions.new(title: quest, q_type: "Paragraph")
          if temp_question.valid?
            if temp_question.save
              temp_question.quest_choices.create(:title => "")
              puts "#{quest} has been addded in company -#{company.full_name}"
            end
          end
        end
      end
    end
#     To create recall types 
    RECALL_TYPES.each_with_index do |recall_type, index|
      if index == 0
        company.recall_types.create(name: recall_type, period_name: "Month(s)", period_val: "6")
      else
        company.recall_types.create(name: recall_type, period_name: "Month(s)", period_val: "3")
      end
    end


    APPOINTMENT_NAMES.each_with_index do |appointment, index|
      if index == 0
        appointment = company.appointment_types.create(:name => appointment, :duration_time => 45, default_note_template: "N/A", color_code: "#FDCA86", confirm_email: false, send_reminder: true)
        AppointmentTypesBillableItem.create(appointment_type_id: appointment.id, billable_item_id: company.billable_items.first.try(:id))

        company.users.doctors.each do |doctor|
          AppointmentTypesUser.create(appointment_type_id: appointment.id, user_id: doctor.id)
        end

        # service  = {id: appointment.id , name: appointment.name , is_selected: false}
        # user_info.appointment_services << service
        # user_info.save

      elsif index ==1
        appointment = company.appointment_types.create(:name => appointment, :duration_time => 30, default_note_template: "N/A", color_code: "#b8ffd5", confirm_email: false, send_reminder: true)
        AppointmentTypesBillableItem.create(appointment_type_id: appointment.id, billable_item_id: company.billable_items.second.try(:id))
        company.users.doctors.each do |doctor|
          AppointmentTypesUser.create(appointment_type_id: appointment.id, user_id: doctor.id)
        end

        # service  = {id: appointment.id , name: appointment.name , is_selected: false}
        # user_info.appointment_services << service
        # user_info.save

      end
    end

#   user availability in week days for a business
    practi_avail = PractitionerAvail.new(business_id: business.id, business_name: business.name, practi_info_id: user_info.id)
    if practi_avail.valid?
      practi_avail.save
      Date::DAYNAMES.each_with_index do |day, index|
        if index ==0 || index==6
          practi_avail.days.create(day_name: day, start_hr: 9, start_min: 0, end_hr: 17, end_min: 0, is_selected: false)
          # BusinessAvail.create(day_name: day ,start_hr: 9, start_min: 0, end_hr: 17, end_min: 0 , is_selected: false, business_id: business.id )
        else
          practi_avail.days.create(day_name: day, start_hr: 9, start_min: 0, end_hr: 17, end_min: 0, is_selected: true)
          # BusinessAvail.create(day_name: day ,start_hr: 9, start_min: 0, end_hr: 17, end_min: 0 , is_selected: true, business_id: business.id )
        end
      end
    end

#    Create a default sms-setting for company
    default_sms = Owner.first.default_sm.try(:sms_no)
    sms_setting = company.create_sms_setting(sms_alert_no: 100, default_sms: default_sms.nil? ? 5 : default_sms)

#     Creating default invoice setting of company 
    invoice_setting = company.build_invoice_setting(title: "Tax Invoice", starting_invoice_number: 1, extra_bussiness_information: nil, offer_text: nil, default_notes: nil, show_business_info: false, hide_business_details: false, include_next_appointment: true, status: true)
    if invoice_setting.valid?
      invoice_setting.save
    end

#   	default referral types with inactive status
    ["Contact", "Other", "Patient"].each do |item|
      company.referral_types.create(referral_source: item, status: STATUS[0])
    end

#    Creating a default AppointmentReminder of company
    appointment_reminder = company.build_appointment_reminder(d_reminder_type: "SMS & Email", reminder_time: "1", reminder_period: "1", ac_email_subject: "Appointment - {{Business.Name}}", reminder_email_subject: "Appointment Reminder")
    if appointment_reminder.valid?
      appointment_reminder.save
    end


#    creating document and printing setting  for new company
    document_and_printing = company.build_document_and_printing(logo_height: "60", in_page_size: "A4", in_top_margin: "10", as_title: "Account Statement", l_space_un_logo: "21", l_top_margin: "15", l_bottom_margin: "20", l_bleft_margin: "15", l_right_margin: "15", tn_page_size: "A4", tn_top_margin: "10", l_display_logo: true, tn_display_logo: true, hide_us_cb: false)
    if document_and_printing.valid?
      document_and_printing.save
    end

    company.create_dashboard_report()


#     To create subscription plan
    default_plan = Plan.where(["no_doctors = ? AND category = ? ", 5, "Monthly"]).first
    subscription =company.build_subscription(name: default_plan.name, doctors_no: default_plan.no_doctors, cost: default_plan.price, category: default_plan.category, purchase_date: Date.today, end_date: Date.today+30.days, :is_trial => true)
    if subscription.valid?
      subscription.save
    end
# Adding sms trail number
    country_code = company.country rescue 'CA'
    company.create_sms_number(number: PhonyRails.normalize_number(SMS_TRIAL_NO[:stage], country_code: country_code))
  end

  def after_update(company)
    account = company.build_account(first_name: company.first_name, last_name: company.last_name, email: company.email, country: company.country, time_zone: company.time_zone, attendees: company.attendees, note_letter: company.note_letter, show_finance: company.show_finance, show_attachment: company.show_attachment, communication_email: company.communication_email, calendar_setting: company.calendar_setting, multi_appointment: company.multi_appointment, show_time_indicator: company.show_time_indicator, patient_name_by: company.patient_name_by, company_name: company.company_name, company_id: company.id)
    if account.valid?
      account.save
    end
    user = company.users.last
    unless user.nil?
      user.update_attributes(:first_name => company.first_name, :last_name => company.last_name, :time_zone => company.time_zone)
      if user.valid?
        puts "User is updated successfully "
      else
        puts "User is not updated"
      end
    else
      puts "Sorry ! User not found"
    end

  end
end
