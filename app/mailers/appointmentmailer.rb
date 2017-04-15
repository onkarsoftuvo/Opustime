class Appointmentmailer < ApplicationMailer
  default from: 'notifications@opustime.com'
  
  def appointment_cancellation(appointment_id)
    appnt = Appointment.find_by_id(appointment_id)
    @patient = appnt.patient
    @appointment = appnt 
    @doctor = appnt.user
    @loc = appnt.business
    # displaying company's account logo , if not present then selecting opustime default logo
    #attachments.inline['logo.jpg'] = File.read( Rails.root.join("app", "assets/images/logo.jpg"))
    @image_url = @doctor.company.account.try(:logo)
    attachments.inline['logo.jpg'] =  File.read( Rails.root.join("app", "assets/images/logo.jpg"))
    #attachments.inline['logo.jpg'] = (image_url.nil? ? (File.read( Rails.root.join("app", "assets/images/logo.jpg"))) : image_url)
    # recipients = [@doctor.email]
    # recipients << @patient.email
    mail(to: @doctor.email , subject: 'Appointment Cancellation')
  end

  def appointment_cancellation_for_patient(appointment_id)
    appnt = Appointment.find_by_id(appointment_id)
    @patient = appnt.patient
    @appointment = appnt
    @doctor = appnt.user
    @loc = appnt.business
    # displaying company's account logo , if not present then selecting opustime default logo
    #attachments.inline['logo.jpg'] = File.read( Rails.root.join("app", "assets/images/logo.jpg"))
    @image_url = @doctor.company.account.try(:logo)
    attachments.inline['logo.jpg'] =  File.read( Rails.root.join("app", "assets/images/logo.jpg"))
    #attachments.inline['logo.jpg'] = (image_url.nil? ? (File.read( Rails.root.join("app", "assets/images/logo.jpg"))) : image_url)
    mail(to: @patient.email , subject: 'Appointment Cancellation')
  end

  def reschedule_appointment(appointment_id)
    appnt = Appointment.find_by_id(appointment_id)
    @patient = appnt.patient
    @appointment = appnt
    @doctor = appnt.user
    @loc = appnt.business
    @image_url = @doctor.company.account.try(:logo)
    attachments.inline['logo.jpg'] =  File.read( Rails.root.join("app", "assets/images/logo.jpg"))
    mail(to: @patient.email , subject: ' Reschedule Appointment')
  end

  def doctor_reschedule_appointment(appointment_id)
    appnt = Appointment.find_by_id(appointment_id)
    @patient = appnt.patient
    @appointment = appnt
    @doctor = appnt.user
    @loc = appnt.business
    @image_url = @doctor.company.account.try(:logo)
    attachments.inline['logo.jpg'] =  File.read( Rails.root.join("app", "assets/images/logo.jpg"))
    #attachments.inline['logo.jpg'] = (image_url.nil? ? (File.read( Rails.root.join("app", "assets/images/logo.jpg"))) : image_url)
    mail(to: @doctor.email , subject: 'Patient Reschedule Appointment')
  end

end
