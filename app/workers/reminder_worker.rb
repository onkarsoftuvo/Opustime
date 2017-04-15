# require 'sidekiq-scheduler'
class ReminderWorker
  include Sidekiq::Worker
  include PlivoSms
  include Reminder::ReadyMade
  sidekiq_options retry: false
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*30, name: 'reminder_worker'}

  def perform
    if lock.acquire!
      begin
        appointments =  Appointment.joins(:patient=>[:company]).where(["patients.status =? AND companies.status=? AND appointments.status = ? AND DATE(appointments.appnt_date) > ? AND DATE(appointments.appnt_date)<= ? " , 'active', true , true , Date.today , Date.today+5.days]).includes(:patient=> [:company=>[:appointment_reminder]])
        appointments.each do |apnt|
          company = apnt.patient.company
          reminder_setting = company.appointment_reminder
          day_after_appnt = (apnt.appnt_date.mjd - Date.today.mjd)
          if day_after_appnt == reminder_setting.reminder_period.to_i
            unless (reminder_setting.skip_weekends && (['0','6'].include?(Time.now.strftime('%w'))))
              if ((company.get_reminder_day_time)>= Time.now)  && ( (company.get_reminder_day_time)<= (Time.now + 59.minutes) )
                patient = apnt.patient
                if reminder_setting.apply_reminder_type_to_all
                  unless reminder_setting.d_reminder_type.eql?'None'
                    case reminder_setting.d_reminder_type
                      when 'SMS'
                        sms_ready_and_send(company , patient , apnt) if reminder_setting.sms_enabled
                      when 'Email'
                        ReminderMailer.send_email(company , apnt , patient).deliver unless (patient.email.nil? && !(reminder_setting.reminder_email_enabled))
                      when 'SMS & Email'
                        ReminderMailer.send_email(company , apnt , patient).deliver unless (patient.email.nil? && !(reminder_setting.reminder_email_enabled))
                        sms_ready_and_send(company , patient , apnt) if reminder_setting.sms_enabled
                    end
                  end
                else

                  case patient.reminder_type
                    when 'sms'
                      unless patient.get_primary_contact.nil?
                        (sms_ready_and_send(company , patient , apnt) unless  patient.sms_marketing)
                      end
                    when 'email'
                      ReminderMailer.send_email(company , apnt , patient).deliver unless (patient.email.nil? && !(reminder_setting.reminder_email_enabled))
                    when 'sms & email'
                      ReminderMailer.send_email(company , apnt , patient).deliver unless (patient.email.nil? && !(reminder_setting.reminder_email_enabled))
                      unless patient.get_primary_contact.nil?
                        (sms_ready_and_send(company , patient , apnt) unless  patient.sms_marketing)
                      end
                  end
                end
              end
            end
          end
        end
      ensure
        lock.release!
      end
    end
  end
end

