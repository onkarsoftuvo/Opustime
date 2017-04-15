class AppointmentBookingWorker
  include Sidekiq::Worker
  sidekiq_options retry: true
  include Sidekiq::Lock::Worker
  #
  sidekiq_options lock: {timeout: 1000*30, name: 'appnt_booking_worker'}

  def perform(appnt_id , patient = nil , email_send_to= nil)
    if lock.acquire!
      begin
        # appnt = Appointment.find_by_id(appnt_id)
        puts "===========appntid #{appnt_id} ============ ***** patient #{patient}"
        if patient.nil?
          AppointmentBooking.appointment_booking_alert(appnt_id).deliver_now
          AppointmentBooking.appointment_booking_alert_to_patient(appnt_id ,email_send_to).deliver_now
        else
          AppointmentBooking.appointment_booking_alert_to_patient(appnt_id ,email_send_to).deliver_now
        end
      rescue Exception => e
        puts "===========appntid #{appnt_id} ============ Error : #{e.message}"
      ensure
        lock.release!
      end
    end
  end

end