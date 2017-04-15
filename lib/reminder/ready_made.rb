module Reminder
  module ReadyMade
    def dynamic_email_template(company , appointment , flag = true)
      unless company.nil?
        reminder_setting = company.appointment_reminder
        dynamic_subject , dynamic_content = get_dynamic_subject_and_content(appointment , reminder_setting , flag)

        return dynamic_subject , dynamic_content
      else
        return nil ,nil
      end
    end

    def dynamic_sms_reminder(company , appointment)
      unless company.nil?

        # removing extra spaces from html
        # half_msg = company.appointment_reminder.try(:sms_text).split('<').map{|k| k.last.blank? ? k.chop : k.strip }.join('<')
        # coming_sms = half_msg.split('>').map{|k|  k.strip }.join('>')
        # (sms_content = coming_sms + '>') if half_msg.last == '>'

        coming_sms =  company.appointment_reminder.try(:sms_text).split(',').map{|k| k.gsub(/[[:space:]]/ ,' ') }
        coming_sms = coming_sms.map{|k|  (k.blank? || k.empty?) ? coming_sms.delete(k) : k }.join(',')

        half_msg = coming_sms.split('<').map{|k| k.gsub(/[[:space:]]/ ,' ') }.join('<')
        coming_sms = half_msg.split('>').map{|k|  k.gsub(/[[:space:]]/ ,' ') }.join('>')
        (sms_content = coming_sms + '>') if half_msg.last == '>'

        # here

        replace_data = matcher_var(appointment.patient, appointment.user, appointment.business , appointment)
        matcher = /#{replace_data.keys.join('|')}/
        unless sms_content.nil?
          return Nokogiri::HTML(sms_content.gsub(matcher, replace_data)).text
        else
          return "Hi, Appointment is on #{appointment.date_and_time_without_name} with practitioner #{appointment.user.full_name_with_title} at location #{appointment.business.try(:name)}"
        end
      else
        return nil
      end
    end

    # send sms and deduct by one , their generate logs

    def sms_ready_and_send(comp , patient , appnt)
      if comp.sms_setting.default_sms > 0
        plivo_obj = PlivoSms::Sms.new
        src_no = comp.sms_number.number
        receiver_no = patient.get_primary_contact.phony_normalized
        sms_body = dynamic_sms_reminder(comp , appnt)
        sms_body = Nokogiri::HTML(sms_body.gsub(/<\/?[^>]+>/, ' ')).text
        response = plivo_obj.send_sms(src_no , receiver_no , sms_body)
        if [200, 202].include? response[0]
          # deduct_in_sms_default_no(comp.sms_setting)
          create_communication_log(comp , receiver_no , src_no , sms_body , patient.id)
        end
      end
    end

    def sms_reminder_default_sms(comp)
      if comp.sms_setting.sms_alert_no > comp.sms_setting.default_sms
        plivo_obj = PlivoSms::Sms.new
        src_no = comp.sms_number.number
        ac_admin = comp.find_admin
        sms_body = "Hi #{ac_admin.full_name_with_title}, You're getting low default SMS in opustime.Please purchase any sms plan"
        unless ac_admin.phone.nil?
          plivo_obj.send_sms(src_no , ac_admin.phone , sms_body)
        end
      end
    end

    def forward_patient_reply_sms_setting_no(comp , sender_number , sms_body)
      sms_setting_no = comp.sms_setting.mob_no
      unless ((sms_setting_no.nil?) || (sms_setting_no.blank?))
        if comp.sms_setting.default_sms > 0
          plivo_obj = PlivoSms::Sms.new
          src_no = comp.sms_number.number
          receiver_no = sms_setting_no
          sms_body = "Message from #{sender_number} : #{sms_body}"
          response = plivo_obj.send_sms(src_no , receiver_no , sms_body)
          if [200, 202].include? response[0]
            deduct_in_sms_default_no(comp.sms_setting)
          end
        end
      end
    end

    def forward_patient_reply_sms_setting_email(comp , sender_number , sms_body)
      sms_setting_email = comp.sms_setting.email
      unless ((sms_setting_email.nil?) || (sms_setting_email.blank?))
        ReminderMailer.send_patient_reply_on_email(sms_setting_email , sender_number , sms_body)
      end
    end

    private

    def deduct_in_sms_default_no(sms_setting)
      default_sms_no = sms_setting.default_sms.to_i - 1
      sms_setting.update(default_sms: default_sms_no)
    end

    def create_communication_log(comp , mob_no , src_no , sm_body , patient_id)
      admin_user = comp.find_admin
      SmsLog.public_activity_off
      sms_log = comp.sms_logs.create(contact_to: mob_no, contact_from: src_no, sms_type: SMS_TYPE[1] ,
                                     delivered_on: DateTime.now, status: LOG_STATUS[0], sms_text: sm_body,
                                     object_id: patient_id, object_type: 'Patient')
      Communication.create(comm_time: Time.now, comm_type: 'sms', category: 'SMS Message', direction: 'sent', to: mob_no, from: src_no, message: sm_body, send_status: true, :patient_id => patient_id)

      receiver_person = (sms_log.object) || (sms_log.patient || sms_log.contact || sms_log.user) # choose any one of them
      SmsLog.public_activity_on
      sms_log.create_activity :create, parameters: sms_log.create_activity_log(admin_user, receiver_person, mob_no, sm_body)
    end

    def get_dynamic_subject_and_content(appnt , reminder_setting , confirmation = false)
      if confirmation == true
        email_content = reminder_setting.ac_email_content
        email_subject = reminder_setting.ac_email_subject
      else
        email_content = reminder_setting.reminder_email_content
        email_subject = reminder_setting.reminder_email_subject
      end

      # pattern to replace the data
      replace_data = matcher_var(appnt.patient, appnt.user, appnt.business , appnt)
      matcher = /#{replace_data.keys.join('|')}/

      content_with_html = email_content.nil? ? '' : (email_content.gsub(matcher, replace_data))
      subject_with_html = email_subject.nil? ? '' : (email_subject.gsub(matcher, replace_data))
      return subject_with_html , content_with_html
    end

    def matcher_var(patient = nil, practitioner = nil, business = nil, appnt = nil)
      str = {}
      unless patient.nil?
        pt_tab = PatientTab.first
        str["{{#{pt_tab.full_name}}}"] = "#{patient.full_name}"
        str["{{#{pt_tab.title}}}"] = "#{patient.title}"
        str["{{#{pt_tab.first_name}}}"] = "#{patient.first_name}"
        str["{{#{pt_tab.last_name}}}"] = "#{patient.last_name}"
        str["{{#{pt_tab.mobile_number}}}"] = "#{patient.get_mobile_no_type_wise("mobile")}"
        str["{{#{pt_tab.home_number}}}"] = "#{patient.get_mobile_no_type_wise("home")}"
        str["{{#{pt_tab.work_number}}}"] = "#{patient.get_mobile_no_type_wise("work")}"
        str["{{#{pt_tab.fax_number}}}"] = "#{patient.get_mobile_no_type_wise("fax")}"
        str["{{#{pt_tab.other_number}}}"] = "#{patient.get_mobile_no_type_wise("other")}"
        str["{{#{pt_tab.email}}}"] = "#{patient.email}"
        str["{{#{pt_tab.address}}}"] = "#{patient.address}"
        str["{{#{pt_tab.city}}}"] = "#{patient.city}"
        str["{{#{pt_tab.post_code}}}"] = "#{patient.postal_code}"
        str["{{#{pt_tab.state}}}"] = "#{patient.state}"
        str["{{#{pt_tab.country}}}"] = "#{patient.country}"
        str["{{#{pt_tab.gender}}}"] = "#{patient.gender}"
        str["{{#{pt_tab.occupation}}}"] = "#{patient.occupation}"
        str["{{#{pt_tab.emergency_contact}}}"] = "#{patient.emergency_contact}"
        str["{{#{pt_tab.referral_source}}}"] = "#{patient.get_referral_source}" #
        str["{{#{pt_tab.medicare_number}}}"] = "#{patient.medicare_number}"
        str["{{#{pt_tab.id_number}}}"] = "#{patient.id}"
        str["{{#{pt_tab.notes}}}"] = "#{patient.notes}"
      end

      unless practitioner.nil?            # key value for practitoner  tab
        pract_tab = PractitionerTab.first
        str["{{#{pract_tab.full_name}}}"] = "#{practitioner.full_name}"
        str["{{#{pract_tab.full_name_with_title}}}"] = "#{practitioner.full_name_with_title}"
        str["{{#{pract_tab.title}}}"] = "#{practitioner.title}"
        str["{{#{pract_tab.first_name}}}"] = "#{practitioner.first_name}"
        str["{{#{pract_tab.last_name}}}"] = "#{practitioner.last_name}"
        str["{{#{pract_tab.designation}}}"] = "#{practitioner.try(:practi_info).try(:designation)}"
        str["{{#{pract_tab.email}}}"] = "#{practitioner.email}"
        str["{{#{pract_tab.mobile_number}}}"] = "#{practitioner.phone}"
      end

      unless business.nil?                  #  key value for business tab
        bs_tab = BusinessTab.first
        str["{{#{bs_tab.name}}}"] = "#{business.name}"
        str["{{#{bs_tab.full_address}}}"] = "#{business.full_address}" #
        str["{{#{bs_tab.address}}}"] = "#{business.address}"
        str["{{#{bs_tab.city}}}"] = "#{business.city}"
        str["{{#{bs_tab.state}}}"] = "#{business.state}"
        str["{{#{bs_tab.post_code}}}"] = "#{business.pin_code}"
        str["{{#{bs_tab.country}}}"] = "#{business.country}"
        str["{{#{bs_tab.registration_name}}}"] = "#{business.reg_name}"
        str["{{#{bs_tab.registration_value}}}"] = "#{business.reg_number}"
        str["{{#{bs_tab.website_address}}}"] = "#{business.web_url}"
        str["{{#{bs_tab.ContactInformation}}}"] = "#{business.contact_info}"
      end

      unless appnt.nil?
        str['{{Appointment.Date}}'] = "#{appnt.appnt_date} "
        str['{{Appointment.StartTime}}'] = "#{appnt.appnt_time_start.strftime("%H:%M %p")} "
        str['{{Appointment.EndTime}}'] = "#{appnt.appnt_time_end.strftime("%H:%M %p")} "
        str['{{Appointment.Type}}'] = "#{appnt.appointment_type.try(:name)}"
      end

      return str
    end


  end

end