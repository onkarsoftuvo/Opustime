class ReminderMailer < ApplicationMailer
  include Reminder::ReadyMade
  default from: 'no-reply@opustime.com'

  def send_email(company , apnt , patient)
    @appnt = apnt
    @user = @appnt.try(:user)
    @appnt_type = @appnt.appointment_type
    @url_cancel  = "http://app.opustime.com/booking#/cancellation/#{@appnt.try(:id)}?comp_id=#{company.id}"
    @url_reschedule  = "http://app.opustime.com/booking#/rescheduling/#{@appnt.try(:id)}?comp_id=#{company.id}"
    email_subject ,  @email_content =  dynamic_email_template(company , apnt , false)
    Communication.create(comm_time: Time.now, comm_type: 'email', category: 'Email-Reminder', direction: 'sent', to: patient.email , from: 'no-reply@opustime.com' , message: (Nokogiri::HTML(@email_content).text) , send_status: true, :patient_id => patient.id)
    attachments.inline['small_watch_black.png'] = File.read( Rails.root.join("app", "assets/images/small_watch_black.png"))  if (@email_content.nil? || @email_content.blank?)
    unless email_subject.nil? || email_subject.blank?
      mail(to: patient.email , subject: email_subject )
    else
      mail(to: patient.email , subject: 'Appointment Notification !' )
    end

  end

  def send_patient_reply_on_email(email , sender_num , sms_body)
    sms_subject = "Opustime message from #{sender_num}"
    @body = sms_body
    mail(to: email , subject: sms_subject)
  end




end
