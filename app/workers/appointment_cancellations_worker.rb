class AppointmentCancellationsWorker 
  include Sidekiq::Worker
  sidekiq_options retry: true
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*30, name: 'appnt_booking_cancellation_worker'}
  
  def perform(appnt_id)
    if lock.acquire!
      begin
        @appointment = Appointment.find_by_id(appnt_id)
        Appointmentmailer.appointment_cancellation(@appointment).deliver
      ensure
        lock.release!
      end
    end
  end
end

