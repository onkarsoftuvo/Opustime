class AppointmentBooking < ApplicationMailer
  default from: 'notifications@opustime.com'
  include Reminder::ReadyMade

  def appointment_booking_alert(appnt_id)
    @appnt = Appointment.find_by_id(appnt_id)
    @user = @appnt.try(:user)
    apnt_date = @appnt.appnt_date.to_date.strftime("%A,%d %B %Y")
    apnt_start_time = @appnt.appnt_time_start.strftime(" at %H:%M%p")
    @appnt_date = apnt_date + apnt_start_time
    @patient = @appnt.patient
    @patient_contact = @patient.patient_contacts.first.try(:contact_no)

    email_subject , @email_content = dynamic_email_template(@user.company , @appnt ,  true)
    Communication.create(comm_time: Time.now, comm_type: 'email', category: 'Appointment confirmation', direction: 'sent', to: @patient.email , from: 'no-reply@opustime.com' , message: (Nokogiri::HTML(@email_content).text) , send_status: true, :patient_id => @patient.id)
    if (@email_content.nil? || @email_content.blank?)
      attachments.inline['logo.jpg'] = File.read( Rails.root.join('app', 'assets/images/logo.jpg'))
      mail(to: @user.email, subject: 'New online booking')
    else
      mail(to: @user.email, subject: email_subject )
    end
  end
  
  def appointment_booking_alert_to_patient(appnt_id , other_email= nil)
    @appnt = Appointment.find_by_id(appnt_id)
    @user = @appnt.try(:user)
    # @url_cancel  = "http://54.174.95.69/booking#/cancellation/#{@appnt.try(:id)}?comp_id=#{@appnt.try(:patient).try(:company).try(:id)}"
    # @url_reschedule  = "http://54.174.95.69/booking#/rescheduling/#{@appnt.try(:id)}?comp_id=#{@appnt.try(:patient).try(:company).try(:id)}"
    company = @appnt.try(:patient).try(:company)
    domain_name = 'app'
    if company.present?
      domain_name = company.company_name.to_s.downcase.gsub(' ','-')
    end
    @url_cancel  = "https://#{domain_name}.opustime.com/booking#/cancellation/#{@appnt.try(:id)}?comp_id=#{@appnt.try(:patient).try(:company).try(:id)}"
    @url_reschedule  = "https://#{domain_name}.opustime.com/booking#/rescheduling/#{@appnt.try(:id)}?comp_id=#{@appnt.try(:patient).try(:company).try(:id)}"

    # @url_cancel  = "http://192.168.1.205:3000/booking#/cancellation/#{@appnt.try(:id)}?comp_id=#{@appnt.try(:patient).try(:company).try(:id)}"
    # @url_reschedule  = "http://192.168.1.205:3000/booking#/rescheduling/#{@appnt.try(:id)}?comp_id=#{@appnt.try(:patient).try(:company).try(:id)}"
    apnt_date = @appnt.appnt_date.to_date.strftime("%A,%d %B %Y")
    apnt_start_time = @appnt.appnt_time_start.strftime(" at %H:%M%p")
    @appnt_date = apnt_date + apnt_start_time
    @appnt_type = @appnt.appointment_type
    patient = @appnt.patient
    send_to_email = other_email.nil? ? patient.email : other_email
    email_subject , @email_content = dynamic_email_template(@user.company , @appnt ,  true)
    Communication.create(comm_time: Time.now, comm_type: 'email', category: 'Appointment confirmation to Patient(#{patient.full_name})', direction: 'sent', to: patient.email , from: 'no-reply@opustime.com' , message: (Nokogiri::HTML(@email_content).text) , send_status: true, :patient_id => patient.id)
    if (@email_content.nil? || @email_content.blank?)
      attachments.inline['small_watch_black.png'] = File.read( Rails.root.join("app", "assets/images/small_watch_black.png"))
      mail(to: send_to_email, subject: 'OpusTime Notification')
    else
      mail(to: send_to_email, subject: email_subject )
    end

  end
end
